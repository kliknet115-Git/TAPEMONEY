import Foundation
import SwiftData

/// Catatan transaksi yang berhasil dibaca dari chip fisik kartu (sesuai Bab 11.3 PRD)
@Model
public final class TransactionRecord {
    @Attribute(.unique) public var id: UUID
    public var transactionDate: Date?
    public var amount: Int?
    public var transactionType: String?
    public var merchantLocation: String?
    public var recordSequence: Int?
    public var source: String // "on_card" / "official_integration" / "manual"

    public var scanRecord: ScanRecord?

    public init(
        id: UUID = UUID(),
        scanRecord: ScanRecord? = nil,
        transactionDate: Date? = nil,
        amount: Int? = nil,
        transactionType: String? = "Pembayaran",
        merchantLocation: String? = nil,
        recordSequence: Int? = nil,
        source: String = "on_card"
    ) {
        self.id = id
        self.scanRecord = scanRecord
        self.transactionDate = transactionDate
        self.amount = amount
        self.transactionType = transactionType
        self.merchantLocation = merchantLocation
        self.recordSequence = recordSequence
        self.source = source
    }

    public var formattedAmount: String {
        guard let amount = amount else { return "-" }
        let sign = (transactionType?.lowercased().contains("top") == true) ? "+" : "-"
        return "\(sign) \(CardProfile.formatCurrency(abs(amount)))"
    }

    public var formattedDate: String {
        guard let date = transactionDate else { return "Tanggal tidak tercatat di kartu" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
