import Foundation
import CoreNFC

/// Adapter untuk Mandiri e-money (sesuai PRD Bab 5 & Bab 6)
public final class MandiriEMoneyAdapter: EMoneyCardAdapter {
    public let issuer: CardIssuer = .mandiri
    public let issuerName: String = "Mandiri e-money"
    public let adapterVersion: String = "2.0"

    // Mandiri e-money ISO 7816 AID (Mandiri Pre-Paid Card Application)
    public static let emoneyAID = APDUCommand.dataFromHex("A0000000040001")

    public init() {}

    public func canHandle(_ tag: DetectedNFCTag) -> Bool {
        switch tag {
        case .iso7816, .miFare:
            return true
        case .mock(_, let typeName):
            return typeName.contains("Mandiri") || typeName.contains("e-money")
        default:
            return false
        }
    }

    public func readCardInfo(from tag: DetectedNFCTag) async throws -> CardReadResult {
        let maskedId = tag.maskedIdentifier

        switch tag {
        case .iso7816(let isoTag):
            return try await readISO7816(tag: isoTag, maskedId: maskedId)
        case .mock:
            return mockSuccessResult(maskedId: maskedId)
        default:
            return CardReadResult(
                issuer: .mandiri,
                cardType: "Mandiri e-money",
                cardGeneration: "Versi Lama",
                maskedIdentifier: maskedId,
                balance: nil,
                balanceStatus: .unsupportedVersion,
                historyStatus: .unavailable,
                rawDiagnosticMessage: "Kartu e-money versi lama berbasis Mifare Classic memerlukan reader dengan Secure Access Module (SAM)",
                adapterVersion: adapterVersion
            )
        }
    }

    private func readISO7816(tag: NFCISO7816Tag, maskedId: String) async throws -> CardReadResult {
        // Select AID Mandiri
        let selectCmd = APDUCommand.selectAID(Self.emoneyAID)
        guard let apdu = selectCmd.toNFCISO7816APDU() else { throw NFCError.invalidAPDU }

        let (respData, sw1, sw2) = try await tag.sendCommand(apdu: apdu)
        let selectResp = APDUResponse(responseData: respData, sw1: sw1, sw2: sw2)

        guard selectResp.isSuccess else {
            return CardReadResult(
                issuer: .mandiri,
                cardType: "Mandiri e-money",
                cardGeneration: nil,
                maskedIdentifier: maskedId,
                balance: nil,
                balanceStatus: .notVerified,
                historyStatus: .unavailable,
                rawDiagnosticMessage: "AID e-money tidak merespons: \(selectResp.statusDescription)",
                adapterVersion: adapterVersion
            )
        }

        // Perintah Get Balance Mandiri (ISO 7816 Read Binary / Get Data)
        let getBalanceCmd = APDUCommand(cla: 0x00, ins: 0xB0, p1: 0x82, p2: 0x00, data: nil, le: 0x04)
        var balance: Int? = nil
        var balanceStatus: CompatibilityStatus = .unavailable

        if let bApdu = getBalanceCmd.toNFCISO7816APDU() {
            let (bData, bSw1, bSw2) = try await tag.sendCommand(apdu: bApdu)
            let bResp = APDUResponse(responseData: bData, sw1: bSw1, sw2: bSw2)
            if bResp.isSuccess && bData.count >= 4 {
                let val = bData.prefix(4).reduce(0) { ($0 << 8) | Int($1) }
                if val >= 0 && val <= 20_000_000 {
                    balance = val
                    balanceStatus = .success
                }
            }
        }

        return CardReadResult(
            issuer: .mandiri,
            cardType: "Mandiri e-money",
            cardGeneration: "Versi 2 (ISO 7816)",
            maskedIdentifier: maskedId,
            balance: balance,
            balanceStatus: balanceStatus,
            historyStatus: .unavailable,
            transactions: [],
            rawDiagnosticMessage: "Pembacaan saldo Mandiri e-money berhasil via ISO 7816",
            adapterVersion: adapterVersion
        )
    }

    private func mockSuccessResult(maskedId: String) -> CardReadResult {
        let sampleTransactions: [ParsedTransaction] = [
            ParsedTransaction(date: Date().addingTimeInterval(-3600 * 5), amount: 18000, type: "Tol Dalam Kota", merchantOrTerminal: "Gerbang Kuningan", sequence: 1),
            ParsedTransaction(date: Date().addingTimeInterval(-3600 * 28), amount: 12500, type: "Parkir", merchantOrTerminal: "Mall Central Park", sequence: 2),
            ParsedTransaction(date: Date().addingTimeInterval(-3600 * 72), amount: 50000, type: "Top Up Livin'", merchantOrTerminal: "Livin by Mandiri", sequence: 3)
        ]

        return CardReadResult(
            issuer: .mandiri,
            cardType: "Mandiri e-money",
            cardGeneration: "Versi 2.0",
            maskedIdentifier: maskedId,
            balance: 82500,
            balanceStatus: .success,
            historyStatus: .success,
            transactions: sampleTransactions,
            rawDiagnosticMessage: "Simulasi Mandiri e-money Berhasil",
            adapterVersion: adapterVersion
        )
    }
}
