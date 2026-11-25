import Foundation

/// Item transaksi domain hasil pembacaan adapter sebelum disimpan ke database
public struct ParsedTransaction: Identifiable, Sendable, Equatable {
    public let id = UUID()
    public let date: Date?
    public let amount: Int?
    public let type: String
    public let merchantOrTerminal: String?
    public let sequence: Int?

    public init(
        date: Date?,
        amount: Int?,
        type: String = "Pembayaran",
        merchantOrTerminal: String? = nil,
        sequence: Int? = nil
    ) {
        self.date = date
        self.amount = amount
        self.type = type
        self.merchantOrTerminal = merchantOrTerminal
        self.sequence = sequence
    }
}

/// Hasil akhir dari eksekusi adapter pembaca kartu (sesuai Bab 6.4 PRD)
public struct CardReadResult: Sendable, Equatable {
    public let issuer: CardIssuer
    public let cardType: String
    public let cardGeneration: String?
    public let maskedIdentifier: String
    public let balance: Int?
    public let balanceStatus: CompatibilityStatus
    public let historyStatus: CompatibilityStatus
    public let transactions: [ParsedTransaction]
    public let rawDiagnosticMessage: String?
    public let adapterVersion: String

    public init(
        issuer: CardIssuer,
        cardType: String,
        cardGeneration: String? = nil,
        maskedIdentifier: String,
        balance: Int? = nil,
        balanceStatus: CompatibilityStatus,
        historyStatus: CompatibilityStatus,
        transactions: [ParsedTransaction] = [],
        rawDiagnosticMessage: String? = nil,
        adapterVersion: String = "2.0"
    ) {
        self.issuer = issuer
        self.cardType = cardType
        self.cardGeneration = cardGeneration
        self.maskedIdentifier = maskedIdentifier
        self.balance = balance
        self.balanceStatus = balanceStatus
        self.historyStatus = historyStatus
        self.transactions = transactions
        self.rawDiagnosticMessage = rawDiagnosticMessage
        self.adapterVersion = adapterVersion
    }
}
