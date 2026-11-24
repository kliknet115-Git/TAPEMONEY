import Foundation

/// Registry penyimpan dan penyeleksi adapter kartu uang elektronik (sesuai Bab 6.2 PRD)
public final class CardAdapterRegistry: Sendable {
    public static let shared = CardAdapterRegistry()

    public let adapters: [any EMoneyCardAdapter]
    private let fallbackAdapter: UnknownCardAdapter

    public init() {
        self.adapters = [
            BCAFlazzAdapter(),      // Pilot Candidate (Tahap 2)
            MandiriEMoneyAdapter(),
            BNITapCashAdapter(),
            BRIBrizzIAdapter()
        ]
        self.fallbackAdapter = UnknownCardAdapter()
    }

    /// Menemukan adapter yang cocok untuk tag yang terdeteksi
    public func resolveAdapter(for tag: DetectedNFCTag) -> any EMoneyCardAdapter {
        for adapter in adapters {
            if adapter.canHandle(tag) {
                return adapter
            }
        }
        return fallbackAdapter
    }
}
