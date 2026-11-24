import Foundation
import CoreNFC
import Combine

/// Status fase sesi pemindaian NFC
public enum NFCScanState: Equatable {
    case idle
    case checkingAvailability
    case waitingForCard
    case cardDetected(protocolDesc: String)
    case readingData
    case success(CardReadResult)
    case failed(String)
    case unsupported(String)
    case cancelled
}

/// Koordinator NFC yang mengelola `NFCTagReaderSession` dan delegasi Core NFC (sesuai Bab 6.3 & FR-001 - FR-004 PRD)
@MainActor
public final class NFCScanCoordinator: NSObject, ObservableObject {
    @Published public var state: NFCScanState = .idle
    @Published public var isScanning: Bool = false
    @Published public var lastResult: CardReadResult? = nil
    @Published public var errorMessage: String? = nil

    private var tagSession: NFCTagReaderSession?
    private let adapterRegistry = CardAdapterRegistry.shared

    /// Cek apakah hardware dan software iPhone mendukung pembacaan NFC (FR-001)
    public var isNFCAvailable: Bool {
        #if targetEnvironment(simulator)
        return true // Simulator mendukung mode simulasi TAPEMONEY
        #else
        return NFCTagReaderSession.readingAvailable
        #endif
    }

    /// Memulai pemindaian NFC (FR-002)
    public func beginScanning() {
        guard isNFCAvailable else {
            self.state = .failed("iPhone ini tidak mendukung pembacaan NFC untuk aplikasi.")
            self.errorMessage = "NFC tidak tersedia pada perangkat ini."
            return
        }

        #if targetEnvironment(simulator)
        // Jalankan mock scan untuk kenyamanan pengujian di Xcode Simulator
        simulateMockScan(issuer: .bca)
        #else
        startRealNFCSession()
        #endif
    }

    /// Simulasi manual untuk pengujian UI dan skenario tanpa kartu fisik
    public func simulateMockScan(issuer: CardIssuer) {
        self.isScanning = true
        self.state = .waitingForCard
        self.errorMessage = nil

        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            self.state = .cardDetected(protocolDesc: "ISO 7816 Smart Card")

            try? await Task.sleep(nanoseconds: 800_000_000)
            self.state = .readingData

            try? await Task.sleep(nanoseconds: 900_000_000)
            let mockTag = DetectedNFCTag.mock(
                identifier: Data([0x04, 0xA2, 0xB3, 0xC4, 0xD5, 0xE6, 0xF7]),
                typeName: issuer.brandName
            )
            let adapter = self.adapterRegistry.resolveAdapter(for: mockTag)
            do {
                let result = try await adapter.readCardInfo(from: mockTag)
                self.lastResult = result
                self.state = .success(result)
                self.isScanning = false
            } catch {
                self.state = .failed(error.localizedDescription)
                self.isScanning = false
            }
        }
    }

    public func cancelScanning() {
        tagSession?.invalidate()
        tagSession = nil
        isScanning = false
        state = .cancelled
    }

    // MARK: - Real Core NFC Session
    private func startRealNFCSession() {
        guard NFCTagReaderSession.readingAvailable else {
            self.state = .failed("Pembacaan NFC sedang tidak tersedia. Coba kembali.")
            return
        }

        // NFCTagReaderSession mendukung polling ISO7816, ISO15693, FeliCa, dan MIFARE
        tagSession = NFCTagReaderSession(
            pollingOption: [.iso14443, .iso15693],
            delegate: self,
            queue: nil
        )
        tagSession?.alertMessage = "Tempelkan kartu e-money pada bagian belakang atas iPhone Anda."
        tagSession?.begin()

        self.isScanning = true
        self.state = .waitingForCard
    }
}

// MARK: - NFCTagReaderSessionDelegate
extension NFCScanCoordinator: NFCTagReaderSessionDelegate {
    public nonisolated func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        Task { @MainActor in
            self.state = .waitingForCard
        }
    }

    public nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            self.isScanning = false
            let nfcError = error as NSError
            if nfcError.code == NFCReaderError.readerSessionInvalidationErrorUserCanceled.rawValue {
                self.state = .cancelled
            } else if nfcError.code == NFCReaderError.readerSessionInvalidationErrorSessionTimeout.rawValue {
                self.state = .failed("Kartu belum terbaca. Posisikan kartu dekat area NFC dan coba lagi.")
            } else {
                self.state = .failed("Sesi pemindaian berakhir: \(error.localizedDescription)")
            }
            self.tagSession = nil
        }
    }

    public nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let firstTag = tags.first else { return }

        // Jika lebih dari 1 tag terdeteksi
        if tags.count > 1 {
            session.alertMessage = "Lebih dari satu kartu terdeteksi. Harap jauhkan kartu lain."
            session.restartPolling()
            return
        }

        Task { @MainActor in
            self.state = .cardDetected(protocolDesc: "Kartu Terdeteksi")
        }

        session.connect(to: firstTag) { [weak self] (error: Error?) in
            guard let self = self else { return }

            if let error = error {
                session.invalidate(errorMessage: "Gagal terhubung dengan kartu: \(error.localizedDescription)")
                Task { @MainActor in
                    self.state = .failed("Kartu terlepas sebelum pembacaan selesai.")
                }
                return
            }

            // Identifikasi Tag Type
            let detectedTag: DetectedNFCTag
            switch firstTag {
            case .iso7816(let isoTag):
                detectedTag = .iso7816(isoTag)
            case .miFare(let miFareTag):
                detectedTag = .miFare(miFareTag)
            case .feliCa(let feliCaTag):
                detectedTag = .feliCa(feliCaTag)
            case .iso15693(let iso15693Tag):
                detectedTag = .iso15693(iso15693Tag)
            @unknown default:
                session.invalidate(errorMessage: "Tipe tag NFC tidak dikenali.")
                Task { @MainActor in
                    self.state = .unsupported("Tag NFC terdeteksi, tetapi bukan kartu yang didukung.")
                }
                return
            }

            Task { @MainActor in
                self.state = .readingData
                session.alertMessage = "Membaca data kartu, tahan posisi kartu..."

                let adapter = self.adapterRegistry.resolveAdapter(for: detectedTag)
                do {
                    let result = try await adapter.readCardInfo(from: detectedTag)
                    self.lastResult = result
                    self.state = .success(result)
                    session.alertMessage = "Pembacaan berhasil!"
                    session.invalidate()
                } catch {
                    session.invalidate(errorMessage: "Gagal membaca: \(error.localizedDescription)")
                    self.state = .failed(error.localizedDescription)
                }
                self.isScanning = false
            }
        }
    }
}
