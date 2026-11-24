import Foundation
import CoreNFC

/// Abstraksi tag NFC yang terdeteksi oleh reader session iOS
public enum DetectedNFCTag {
    case iso7816(NFCISO7816Tag)
    case miFare(NFCMiFareTag)
    case feliCa(NFCFeliCaTag)
    case iso15693(NFCISO15693Tag)
    case mock(identifier: Data, typeName: String)

    public var tagIdentifier: Data {
        switch self {
        case .iso7816(let tag):
            return tag.identifier
        case .miFare(let tag):
            return tag.identifier
        case .feliCa(let tag):
            return tag.currentIDm
        case .iso15693(let tag):
            return tag.identifier
        case .mock(let identifier, _):
            return identifier
        }
    }

    public var hexIdentifier: String {
        tagIdentifier.map { String(format: "%02hhX", $0) }.joined()
    }

    public var maskedIdentifier: String {
        let hex = hexIdentifier
        guard hex.count >= 8 else { return "••••" }
        let start = hex.prefix(4)
        let end = hex.suffix(4)
        return "\(start) •••• •••• \(end)"
    }

    public var protocolDescription: String {
        switch self {
        case .iso7816: return "ISO 7816 Smart Card"
        case .miFare: return "MIFARE Desfire / Classic"
        case .feliCa: return "FeliCa"
        case .iso15693: return "ISO 15693 Vicinity Tag"
        case .mock(_, let typeName): return "Simulator Mock (\(typeName))"
        }
    }
}
