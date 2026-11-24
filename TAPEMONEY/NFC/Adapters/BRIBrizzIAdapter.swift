import Foundation
import CoreNFC

/// Adapter untuk BRI BRIZZI (sesuai PRD Bab 5)
public final class BRIBrizzIAdapter: EMoneyCardAdapter {
    public let issuer: CardIssuer = .bri
    public let issuerName: String = "BRI BRIZZI"
    public let adapterVersion: String = "2.0"

    // BRIZZI ISO 7816 AID (BRI Pre-Paid Card Application)
    public static let brizziAID = APDUCommand.dataFromHex("A0000000060001")

    public init() {}

    public func canHandle(_ tag: DetectedNFCTag) -> Bool {
        switch tag {
        case .iso7816, .miFare:
            return true
        case .mock(_, let typeName):
            return typeName.contains("BRI") || typeName.contains("BRIZZI")
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
                issuer: .bri,
                cardType: "BRI BRIZZI",
                cardGeneration: "Gen 1 (Mifare Classic)",
                maskedIdentifier: maskedId,
                balance: nil,
                balanceStatus: .unsupportedVersion,
                historyStatus: .unavailable,
                rawDiagnosticMessage: "BRIZZI versi lama membutuhkan terminal bersertifikasi SAM BRI",
                adapterVersion: adapterVersion
            )
        }
    }

    private func readISO7816(tag: NFCISO7816Tag, maskedId: String) async throws -> CardReadResult {
        let selectCmd = APDUCommand.selectAID(Self.brizziAID)
        guard let apdu = selectCmd.toNFCISO7816APDU() else { throw NFCError.invalidAPDU }

        let (respData, sw1, sw2) = try await tag.sendCommand(apdu: apdu)
        let selectResp = APDUResponse(responseData: respData, sw1: sw1, sw2: sw2)

        guard selectResp.isSuccess else {
            return CardReadResult(
                issuer: .bri,
                cardType: "BRI BRIZZI",
                cardGeneration: nil,
                maskedIdentifier: maskedId,
                balance: nil,
                balanceStatus: .notVerified,
                historyStatus: .unavailable,
                rawDiagnosticMessage: "AID BRIZZI tidak merespons: \(selectResp.statusDescription)",
                adapterVersion: adapterVersion
            )
        }

        // Perintah Get Balance BRIZZI
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
            issuer: .bri,
            cardType: "BRI BRIZZI",
            cardGeneration: "BRIZZI Gen 2",
            maskedIdentifier: maskedId,
            balance: balance,
            balanceStatus: status,
            historyStatus: .unavailable,
            transactions: [],
            rawDiagnosticMessage: "Pembacaan saldo BRIZZI selesai via ISO 7816",
            adapterVersion: adapterVersion
        )
    }

    private func mockSuccessResult(maskedId: String) -> CardReadResult {
        let sampleTransactions: [ParsedTransaction] = [
            ParsedTransaction(date: Date().addingTimeInterval(-3600 * 12), amount: 10500, type: "Tol Jagorawi", merchantOrTerminal: "Gerbang Cibubur", sequence: 1),
            ParsedTransaction(date: Date().addingTimeInterval(-3600 * 40), amount: 25000, type: "Parkir Bandara", merchantOrTerminal: "Terminal 3 Soekarno Hatta", sequence: 2)
        ]

        return CardReadResult(
            issuer: .bri,
            cardType: "BRI BRIZZI",
            cardGeneration: "Gen 2",
            maskedIdentifier: maskedId,
            balance: 45000,
            balanceStatus: .success,
            historyStatus: .success,
            transactions: sampleTransactions,
            rawDiagnosticMessage: "Simulasi BRI BRIZZI Berhasil",
            adapterVersion: adapterVersion
        )
    }
}
