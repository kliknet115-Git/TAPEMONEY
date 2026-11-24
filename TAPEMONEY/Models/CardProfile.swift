import Foundation
import SwiftData

/// Profil kartu tersimpan pada perangkat pengguna (sesuai Bab 11.1 PRD)
@Model
public final class CardProfile {
    @Attribute(.unique) public var id: UUID
    public var alias: String
    public var issuerRaw: String
    public var cardType: String
    public var cardGeneration: String?
    public var maskedCardIdentifier: String?
    public var createdAt: Date
    public var lastScannedAt: Date?
    public var latestBalance: Int?

    @Relationship(deleteRule: .cascade, inverse: \ScanRecord.cardProfile)
    public var scans: [ScanRecord] = []

    public var issuer: CardIssuer {
        get { CardIssuer(rawValue: issuerRaw) ?? .unknown }
        set { issuerRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        alias: String,
        issuer: CardIssuer,
        cardType: String,
        cardGeneration: String? = nil,
        maskedCardIdentifier: String? = nil,
        createdAt: Date = Date(),
        lastScannedAt: Date? = nil,
        latestBalance: Int? = nil
    ) {
        self.id = id
        self.alias = alias
        self.issuerRaw = issuer.rawValue
        self.cardType = cardType
        self.cardGeneration = cardGeneration
        self.maskedCardIdentifier = maskedCardIdentifier
        self.createdAt = createdAt
        self.lastScannedAt = lastScannedAt
        self.latestBalance = latestBalance
    }

    /// Format display saldo rupiah
    public var formattedBalance: String {
        guard let balance = latestBalance else { return "Rp --" }
        return CardProfile.formatCurrency(balance)
    }

    public static func formatCurrency(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "id_ID")
        formatter.currencySymbol = "Rp "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "Rp \(amount)"
    }
}
