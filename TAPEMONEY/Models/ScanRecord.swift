import Foundation
import SwiftData

/// Catatan setiap sesi scan yang dilakukan pengguna (sesuai Bab 11.2 PRD)
@Model
public final class ScanRecord {
    @Attribute(.unique) public var id: UUID
    public var scannedAt: Date
    public var balance: Int?
    public var balanceStatusRaw: String
    public var historyStatusRaw: String
    public var adapterVersion: String
    public var appVersion: String
    public var deviceModel: String?

    public var cardProfile: CardProfile?

    @Relationship(deleteRule: .cascade, inverse: \TransactionRecord.scanRecord)
    public var transactions: [TransactionRecord] = []

    public var balanceStatus: CompatibilityStatus {
        get { CompatibilityStatus(rawValue: balanceStatusRaw) ?? .unavailable }
        set { balanceStatusRaw = newValue.rawValue }
    }

    public var historyStatus: CompatibilityStatus {
        get { CompatibilityStatus(rawValue: historyStatusRaw) ?? .unavailable }
        set { historyStatusRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        cardProfile: CardProfile? = nil,
        scannedAt: Date = Date(),
        balance: Int? = nil,
        balanceStatus: CompatibilityStatus = .unavailable,
        historyStatus: CompatibilityStatus = .unavailable,
        adapterVersion: String = "1.0",
        appVersion: String = "2.0.0",
        deviceModel: String? = nil
    ) {
        self.id = id
        self.cardProfile = cardProfile
        self.scannedAt = scannedAt
        self.balance = balance
        self.balanceStatusRaw = balanceStatus.rawValue
        self.historyStatusRaw = historyStatus.rawValue
        self.adapterVersion = adapterVersion
        self.appVersion = appVersion
        self.deviceModel = deviceModel
    }

    public var formattedBalance: String {
        guard let balance = balance else { return "Tidak terbaca" }
        return CardProfile.formatCurrency(balance)
    }
}
