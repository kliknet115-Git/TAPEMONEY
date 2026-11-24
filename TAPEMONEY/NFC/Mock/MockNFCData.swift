import Foundation

/// Data mock untuk simulasi dan SwiftUI Previews
public struct MockNFCData {
    public static func sampleCardProfiles() -> [CardProfile] {
        let bcaCard = CardProfile(
            alias: "Flazz Harian Tol",
            issuer: .bca,
            cardType: "BCA Flazz",
            cardGeneration: "Gen 2",
            maskedCardIdentifier: "04A2 •••• •••• E6F7",
            createdAt: Date().addingTimeInterval(-86400 * 14),
            lastScannedAt: Date().addingTimeInterval(-3600 * 2),
            latestBalance: 137000
        )

        let mandiriCard = CardProfile(
            alias: "e-Money Tol Jagorawi",
            issuer: .mandiri,
            cardType: "Mandiri e-money",
            cardGeneration: "Versi 2.0",
            maskedCardIdentifier: "045B •••• •••• C190",
            createdAt: Date().addingTimeInterval(-86400 * 30),
            lastScannedAt: Date().addingTimeInterval(-86400 * 1),
            latestBalance: 82500
        )

        let bniCard = CardProfile(
            alias: "TapCash MRT & TJ",
            issuer: .bni,
            cardType: "BNI TapCash",
            cardGeneration: "Gen 2",
            maskedCardIdentifier: "0411 •••• •••• 98AF",
            createdAt: Date().addingTimeInterval(-86400 * 45),
            lastScannedAt: Date().addingTimeInterval(-86400 * 3),
            latestBalance: 64500
        )

        let briCard = CardProfile(
            alias: "BRIZZI Parkir Cadangan",
            issuer: .bri,
            cardType: "BRI BRIZZI",
            cardGeneration: "Gen 2",
            maskedCardIdentifier: "0489 •••• •••• 33D1",
            createdAt: Date().addingTimeInterval(-86400 * 60),
            lastScannedAt: Date().addingTimeInterval(-86400 * 7),
            latestBalance: 45000
        )

        return [bcaCard, mandiriCard, bniCard, briCard]
    }

    public static func sampleScanResult() -> CardReadResult {
        let tx1 = ParsedTransaction(date: Date().addingTimeInterval(-3600 * 2), amount: 14500, type: "Pembayaran Tol", merchantOrTerminal: "Gerbang Tol Cikarang Utama", sequence: 1)
        let tx2 = ParsedTransaction(date: Date().addingTimeInterval(-3600 * 26), amount: 45000, type: "Retail / Minimarket", merchantOrTerminal: "Indomaret Point", sequence: 2)
        let tx3 = ParsedTransaction(date: Date().addingTimeInterval(-3600 * 50), amount: 3500, type: "Transportasi", merchantOrTerminal: "TransJakarta Halte Monas", sequence: 3)
        let tx4 = ParsedTransaction(date: Date().addingTimeInterval(-3600 * 96), amount: 100000, type: "Top Up Saldo", merchantOrTerminal: "ATM BCA / Mobile", sequence: 4)

        return CardReadResult(
            issuer: .bca,
            cardType: "BCA Flazz",
            cardGeneration: "Gen 2",
            maskedIdentifier: "04A2 •••• •••• E6F7",
            balance: 137000,
            balanceStatus: .success,
            historyStatus: .success,
            transactions: [tx1, tx2, tx3, tx4],
            rawDiagnosticMessage: "ISO 7816 Smart Card APDU Inquiry Berhasil",
            adapterVersion: "2.1-pilot"
        )
    }
}
