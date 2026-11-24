import Foundation

/// Fallback adapter untuk tag NFC yang terdeteksi tetapi belum didukung (sesuai FR-003 & FR-004 PRD)
public final class UnknownCardAdapter: EMoneyCardAdapter {
    public let issuer: CardIssuer = .unknown
    public let issuerName: String = "Kartu Tidak Dikenal"
    public let adapterVersion: String = "1.0"

    public init() {}

    public func canHandle(_ tag: DetectedNFCTag) -> Bool {
        true // Menangani semua tag yang tidak cocok dengan adapter lain
    }

    public func readCardInfo(from tag: DetectedNFCTag) async throws -> CardReadResult {
        return CardReadResult(
            issuer: .unknown,
            cardType: tag.protocolDescription,
            cardGeneration: nil,
            maskedIdentifier: tag.maskedIdentifier,
            balance: nil,
            balanceStatus: .unsupportedVersion,
            historyStatus: .unavailable,
            transactions: [],
            rawDiagnosticMessage: "Tag NFC terdeteksi (\(tag.protocolDescription)), namun bukan merupakan kartu e-money yang didukung atau format data terproteksi.",
            adapterVersion: adapterVersion
        )
    }
}
