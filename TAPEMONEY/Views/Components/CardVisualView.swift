import SwiftUI

/// Representasi visual kartu e-money dengan estetika iOS modern
public struct CardVisualView: View {
    public let issuer: CardIssuer
    public let alias: String
    public let maskedNumber: String?
    public let balance: Int?
    public let cardType: String
    public let cardGeneration: String?
    public let lastScanned: Date?

    public init(
        issuer: CardIssuer,
        alias: String,
        maskedNumber: String? = nil,
        balance: Int? = nil,
        cardType: String? = nil,
        cardGeneration: String? = nil,
        lastScanned: Date? = nil
    ) {
        self.issuer = issuer
        self.alias = alias
        self.maskedNumber = maskedNumber
        self.balance = balance
        self.cardType = cardType ?? issuer.displayName
        self.cardGeneration = cardGeneration
        self.lastScanned = lastScanned
    }

    public var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: issuer.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(20)
            .shadow(color: issuer.primaryColor.opacity(0.35), radius: 12, x: 0, y: 6)

            // Pattern Overlay
            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: geo.size.width * 0.9)
                    .offset(x: geo.size.width * 0.45, y: -geo.size.height * 0.3)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: geo.size.width * 0.7)
                    .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.4)
            }
            .clipped()
            .cornerRadius(20)

            // Card Content
            VStack(alignment: .leading, spacing: 0) {
                // Header: Issuer Logo / Brand & Contactless Icon
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(issuer.brandName.uppercased())
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(1.5)

                        if let gen = cardGeneration {
                            Text(gen)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    Spacer()

                    // NFC Contactless Wave Icon
                    Image(systemName: "wave.3.right.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Smartcard EMV Chip Graphic
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(
                                colors: [Color(red: 0.88, green: 0.78, blue: 0.45), Color(red: 0.72, green: 0.60, blue: 0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 42, height: 32)

                        // Chip lines
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.black.opacity(0.3), lineWidth: 1)
                            .frame(width: 30, height: 20)
                    }

                    Spacer()

                    // Masked Identifier
                    if let number = maskedNumber {
                        Text(number)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                            .tracking(2)
                    }
                }
                .padding(.bottom, 14)

                // Footer: Alias & Balance
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(alias)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        if let date = lastScanned {
                            Text("Scan: \(formattedDate(date))")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Saldo")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                            .textCase(.uppercase)

                        Text(formattedBalance(balance))
                            .font(.system(size: 19, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 205)
    }

    private func formattedBalance(_ amount: Int?) -> String {
        guard let amount = amount else { return "Rp --" }
        return CardProfile.formatCurrency(amount)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
