import Foundation
import CoreNFC

/// Adapter untuk BNI TapCash (sesuai PRD Bab 5)
public final class BNITapCashAdapter: EMoneyCardAdapter {
    public let issuer: CardIssuer = .bni
    public let issuerName: String = "BNI TapCash"
    public let adapterVersion: String = "2.0"

    // BNI TapCash AID (BNI E-Purse ISO 7816)
    public static let tapCashAID = APDUCommand.dataFromHex("A0000000050001")

    public init() {}

    public func canHandle(_ tag: DetectedNFCTag) -> Bool {
        switch tag {
        case .iso7816, .miFare:
            return true
        case .mock(_, let typeName):
            return typeName.contains("BNI") || typeName.contains("TapCash")
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
                issuer: .bni,
                cardType: "BNI TapCash",
                cardGeneration: "Gen 1 (Mifare Classic)",
                maskedIdentifier: maskedId,
                balance: nil,
                balanceStatus: .unsupportedVersion,
                historyStatus: .unavailable,
                rawDiagnosticMessage: "TapCash generasi lama menggunakan enkripsi proprietary Mifare yang tidak didukung Core NFC",
                adapterVersion: adapterVersion
            )
        }
    }

    private func readISO7816(tag: NFCISO7816Tag, maskedId: String) async throws -> CardReadResult {
        let selectCmd = APDUCommand.selectAID(Self.tapCashAID)
        guard let apdu = selectCmd.toNFCISO7816APDU() else { throw NFCError.invalidAPDU }

        let (respData, sw1, sw2) = try await tag.sendCommand(apdu: apdu)
        let selectResp = APDUResponse(responseData: respData, sw1: sw1, sw2: sw2)

        guard selectResp.isSuccess else {
            return CardReadResult(
                issuer: .bni,
                cardType: "BNI TapCash",
                cardGeneration: nil,
                maskedIdentifier: maskedId,
                balance: nil,
                balanceStatus: .notVerified,
                historyStatus: .unavailable,
                rawDiagnosticMessage: "AID BNI TapCash tidak merespons: \(selectResp.statusDescription)",
                adapterVersion: adapterVersion
            )
        }

        // Baca Saldo TapCash
        let getBalCmd = APDUCommand(cla: 0x90, ins: 0x6C, p1: 0x00, p2: 0x00, data: nil, le: 0x04)
        var balance: Int? = nil
        var status: CompatibilityStatus = .unavailable

        if let bApdu = getBalCmd.toNFCISO7816APDU() {
            let (bData, bSw1, bSw2) = try await tag.sendCommand(apdu: bApdu)
            let bResp = APDUResponse(responseData: bData, sw1: bSw1, sw2: bSw2)
            if bResp.isSuccess && bData.count >= 4 {
                let val = bData.prefix(4).reduce(0) { ($0 << 8) | Int($1) }
                if val >= 0 && val <= 20_000_000 {
                    balance = val
                    status = .success
                }
            }
        }

        return CardReadResult(
            issuer: .bni,
            cardType: "BNI TapCash",
            cardGeneration: "TapCash Gen 2",
            maskedIdentifier: maskedId,
            balance: balance,
            balanceStatus: status,
            historyStatus: .unavailable,
            transactions: [],
            rawDiagnosticMessage: "Pembacaan TapCash selesai via ISO 7816",
            adapterVersion: adapterVersion
        )
    }

    private func mockSuccessResult(maskedId: String) -> CardReadResult {
        let sampleTransactions: [ParsedTransaction] = [
            ParsedTransaction(date: Date().addingTimeInterval(-3600 * 8), amount: 14000, type: "MRT Jakarta", merchantOrTerminal: "Stasiun Bundaran HI", sequence: 1),
            ParsedTransaction(date: Date().addingTimeInterval(-3600 * 32), amount: 3500, type: "TransJakarta", merchantOrTerminal: "Halte Tosari", sequence: 2),
            ParsedTransaction(date: Date().addingTimeInterval(-3600 * 60), amount: 50000, type: "Top Up BNI Mobile", merchantOrTerminal: "BNI Mobile Banking", sequence: 3)
        ]

        return CardReadResult(
            issuer: .bni,
            cardType: "BNI TapCash",
            cardGeneration: "Gen 2",
            maskedIdentifier: maskedId,
            balance: 64500,
            balanceStatus: .success,
            historyStatus: .success,
            transactions: sampleTransactions,
            rawDiagnosticMessage: "Simulasi BNI TapCash Berhasil",
            adapterVersion: adapterVersion
        )
    }
}
