import SwiftUI

/// Baris transaksi yang dibaca dari kartu (FR-007 PRD)
public struct TransactionRowView: View {
    public let sequence: Int?
    public let date: Date?
    public let amount: Int?
    public let type: String
    public let merchant: String?

    public init(
        sequence: Int? = nil,
        date: Date?,
        amount: Int?,
        type: String = "Pembayaran",
        merchant: String? = nil
    ) {
        self.sequence = sequence
        self.date = date
        self.amount = amount
        self.type = type
        self.merchant = merchant
    }

    private var isTopUp: Bool {
        type.lowercased().contains("top")
    }

    public var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(isTopUp ? Color.green.opacity(0.15) : Color.blue.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: isTopUp ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isTopUp ? .green : .blue)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(type)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    if let seq = sequence {
                        Text("#\(seq)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(4)
                    }
                }

                if let loc = merchant, !loc.isEmpty {
                    Text(loc)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Text(formattedDate(date))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.8))
            }

            Spacer()

            // Nominal
            Text(formattedAmount(amount))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(isTopUp ? .green : .primary)
        }
        .padding(.vertical, 6)
    }

    private func formattedAmount(_ amount: Int?) -> String {
        guard let amount = amount else { return "-" }
        let sign = isTopUp ? "+" : "-"
        return "\(sign) \(CardProfile.formatCurrency(abs(amount)))"
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Tanggal tidak tercatat di chip" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
