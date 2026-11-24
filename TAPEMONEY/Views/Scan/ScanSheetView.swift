import SwiftUI

/// Lembar Pemindaian NFC dengan animasi dan penanganan status realtime (Bab 10.2 PRD)
public struct ScanSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var nfcCoordinator: NFCScanCoordinator
    @EnvironmentObject private var repository: CardDataRepository

    public let simulationIssuer: CardIssuer?
    @State private var waveAnimation: Bool = false

    public var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Visual NFC Reader Area Animation
                ZStack {
                    // Outer Ripple 2
                    Circle()
                        .stroke(Color.blue.opacity(0.15), lineWidth: 3)
                        .frame(width: waveAnimation ? 240 : 160, height: waveAnimation ? 240 : 160)
                        .scaleEffect(waveAnimation ? 1.05 : 0.95)
                        .opacity(waveAnimation ? 0.3 : 0.8)

                    // Outer Ripple 1
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                        .frame(width: waveAnimation ? 190 : 140, height: waveAnimation ? 190 : 140)

                    // Core NFC Disc
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color(red: 0.1, green: 0.3, blue: 0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.blue.opacity(0.4), radius: 14, x: 0, y: 8)

                    Image(systemName: "wave.3.forward.circle.fill")
                        .font(.system(size: 58))
                        .foregroundColor(.white)
                }
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                        waveAnimation = true
                    }
                }

                // Status Message Box
                VStack(spacing: 12) {
                    Text(statusTitle)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text(statusDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Instruksi Posisi Kartu iPhone
                HStack(spacing: 16) {
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Posisi Sensor NFC")
                            .font(.system(size: 13, weight: .bold))
                        Text("Area NFC iPhone terletak di bagian belakang atas dekat kamera.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(14)
                .padding(.horizontal)

                Spacer()

                // Tombol Aksi
                VStack(spacing: 12) {
                    if case .failed = nfcCoordinator.state {
                        Button {
                            startScanning()
                        } label: {
                            Text("Coba Lagi")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                    }

                    Button {
                        nfcCoordinator.cancelScanning()
                        dismiss()
                    } label: {
                        Text("Batal")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .navigationTitle("Memindai Kartu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tutup") {
                        nfcCoordinator.cancelScanning()
                        dismiss()
                    }
                }
            }
            .onAppear {
                startScanning()
            }
            .navigationDestination(isPresented: Binding(
                get: { nfcCoordinator.lastResult != nil },
                set: { if !$0 { nfcCoordinator.lastResult = nil } }
            )) {
                if let result = nfcCoordinator.lastResult {
                    ScanResultView(result: result) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func startScanning() {
        if let simIssuer = simulationIssuer {
            nfcCoordinator.simulateMockScan(issuer: simIssuer)
        } else {
            nfcCoordinator.beginScanning()
        }
    }

    private var statusTitle: String {
        switch nfcCoordinator.state {
        case .idle:
            return "Siap Memindai"
        case .checkingAvailability:
            return "Memeriksa Sensor..."
        case .waitingForCard:
            return "Tempelkan Kartu"
        case .cardDetected:
            return "Kartu Terdeteksi"
        case .readingData:
            return "Membaca Data..."
        case .success:
            return "Pembacaan Selesai!"
        case .failed(let err):
            return "Gagal Membaca"
        case .unsupported:
            return "Kartu Belum Didukung"
        case .cancelled:
            return "Pemindaian Dibatalkan"
        }
    }

    private var statusDescription: String {
        switch nfcCoordinator.state {
        case .idle, .waitingForCard:
            return "Posisikan kartu e-money menempel kuat di bagian belakang atas iPhone dan tahan posisi kartu."
        case .checkingAvailability:
            return "Menyiapkan reader session Core NFC..."
        case .cardDetected(let protocolDesc):
            return "\(protocolDesc). Mohon jangan jauhkan kartu sampai verifikasi selesai."
        case .readingData:
            return "Mengirim instruksi ISO 7816 APDU dan memverifikasi data saldo..."
        case .success:
            return "Data berhasil dibaca dan diverifikasi dari chip kartu."
        case .failed(let err):
            return err
        case .unsupported(let reason):
            return reason
        case .cancelled:
            return "Sesi pemindaian telah ditutup."
        }
    }
}
