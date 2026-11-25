import Foundation

/// Registry penyimpan dan penyeleksi adapter kartu uang elektronik (sesuai Bab 6.2 PRD)
public final class CardAdapterRegistry: Sendable {
    public static let shared = CardAdapterRegistry()

    public let flazzAdapter: BCAFlazzAdapter
    public let mandiriAdapter: MandiriEMoneyAdapter
    public let tapCashAdapter: BNITapCashAdapter
    public let brizziAdapter: BRIBrizzIAdapter
    public let fallbackAdapter: UnknownCardAdapter

    public init() {
        self.flazzAdapter = BCAFlazzAdapter()
        self.mandiriAdapter = MandiriEMoneyAdapter()
        self.tapCashAdapter = BNITapCashAdapter()
        self.brizziAdapter = BRIBrizzIAdapter()
        self.fallbackAdapter = UnknownCardAdapter()
    }

    /// Menemukan adapter yang cocok untuk tag yang terdeteksi
    public func resolveAdapter(for tag: DetectedNFCTag) -> any EMoneyCardAdapter {
        switch tag {
        case .mock(_, let typeName):
            if typeName.contains("Flazz") || typeName.contains("BCA") { return flazzAdapter }
            if typeName.contains("Mandiri") || typeName.contains("e-money") { return mandiriAdapter }
            if typeName.contains("BNI") || typeName.contains("TapCash") { return tapCashAdapter }
            if typeName.contains("BRI") || typeName.contains("BRIZZI") { return brizziAdapter }
            return fallbackAdapter

        case .iso7816:
            // Gunakan CompositeCardAdapter untuk memverifikasi AID setiap bank secara sekuensial
            return CompositeCardAdapter(
                adapters: [flazzAdapter, mandiriAdapter, tapCashAdapter, brizziAdapter],
                fallback: fallbackAdapter
            )

        case .miFare:
            // Kartu Mifare Classic (legacy) tidak mendukung pembacaan sektor enkripsi tanpa SAM
            return fallbackAdapter

        default:
            return fallbackAdapter
        }
    }
}

/// Adapter gabungan yang secara dinamis mencoba mengidentifikasi bank penerbit kartu ISO 7816 melalui AID probing
public final class CompositeCardAdapter: EMoneyCardAdapter, Sendable {
    public let issuer: CardIssuer = .unknown
    public let issuerName: String = "Multi-Bank Card Detector"
    public let adapterVersion: String = "2.0-composite"

    private let candidateAdapters: [any EMoneyCardAdapter]
    private let fallback: UnknownCardAdapter

    public init(adapters: [any EMoneyCardAdapter], fallback: UnknownCardAdapter) {
        self.candidateAdapters = adapters
        self.fallback = fallback
    }

    public func canHandle(_ tag: DetectedNFCTag) -> Bool { true }

    public func readCardInfo(from tag: DetectedNFCTag) async throws -> CardReadResult {
        // Coba setiap adapter terdaftar
        for adapter in candidateAdapters {
            do {
                let result = try await adapter.readCardInfo(from: tag)
                // Jika AID berhasil dikenali atau saldo berhasil dibaca
                if result.balanceStatus == .success || result.cardGeneration != nil || result.balance != nil {
                    return result
                }
                // Jika AID berhasil di-select namun ada pesan diagnostik khusus kartu tersebut
                if let diag = result.rawDiagnosticMessage,
                   !diag.contains("tidak merespons") &&
                   !diag.contains("0x6A82") &&
                   !diag.contains("Gagal AID") {
                    return result
                }
            } catch {
                continue
            }
        }
        return try await fallback.readCardInfo(from: tag)
    }
}
