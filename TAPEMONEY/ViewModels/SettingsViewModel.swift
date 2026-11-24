import Foundation
import SwiftUI

/// Model entri tabel matriks kompatibilitas
public struct CardMatrixItem: Identifiable {
    public let id = UUID()
    public let issuer: CardIssuer
    public let targetVersion: String
    public let balanceSupport: CompatibilityStatus
    public let historySupport: CompatibilityStatus
    public let notes: String
}

/// ViewModel untuk Pengaturan, Status NFC, dan Diagnostik (Bab 10.6 PRD)
@MainActor
public final class SettingsViewModel: ObservableObject {
    public let repository: CardDataRepository
    public let nfcCoordinator: NFCScanCoordinator

    @Published public var showResetConfirmation: Bool = false
    @Published public var resetSuccess: Bool = false

    public let compatibilityMatrix: [CardMatrixItem] = [
        CardMatrixItem(
            issuer: .bca,
            targetVersion: "Flazz Gen 2 (ISO 7816)",
            balanceSupport: .balanceSupported,
            historySupport: .historySupported,
            notes: "Kandidat pilot. Membaca saldo dan hingga 10 transaksi terakhir yang ada di kartu."
        ),
        CardMatrixItem(
            issuer: .bca,
            targetVersion: "Flazz Gen 1 (Mifare Classic)",
            balanceSupport: .unsupportedVersion,
            historySupport: .unavailable,
            notes: "Membutuhkan autentikasi proprietary yang tidak didukung iOS Core NFC."
        ),
        CardMatrixItem(
            issuer: .mandiri,
            targetVersion: "Mandiri e-money Versi 2.0",
            balanceSupport: .balanceSupported,
            historySupport: .historySupported,
            notes: "Membaca saldo via APDU ISO 7816. Transaksi on-card bervariasi per varian."
        ),
        CardMatrixItem(
            issuer: .bni,
            targetVersion: "BNI TapCash Gen 2",
            balanceSupport: .balanceSupported,
            historySupport: .unavailable,
            notes: "Membaca saldo via AID resmi. Histori chip tergantung izin penerbit."
        ),
        CardMatrixItem(
            issuer: .bri,
            targetVersion: "BRI BRIZZI Gen 2",
            balanceSupport: .balanceSupported,
            historySupport: .unavailable,
            notes: "Cek saldo via APDU query. Histori chip membutuhkan verifikasi spesifik."
        )
    ]

    public init(repository: CardDataRepository, nfcCoordinator: NFCScanCoordinator) {
        self.repository = repository
        self.nfcCoordinator = nfcCoordinator
    }

    public func resetDatabase() {
        do {
            try repository.resetAllData()
            resetSuccess = true
        } catch {
            print("Gagal reset data: \(error)")
        }
    }
}
