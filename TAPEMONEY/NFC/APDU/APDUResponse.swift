import Foundation

/// Respons APDU dari chip kartu ISO 7816
public struct APDUResponse: Sendable {
    public let responseData: Data
    public let sw1: UInt8
    public let sw2: UInt8

    public var statusWord: UInt16 {
        (UInt16(sw1) << 8) | UInt16(sw2)
    }

    public var isSuccess: Bool {
        statusWord == 0x9000 || sw1 == 0x91 // 0x9000 standard OK, 0x9100 Mifare Desfire native success
    }

    public init(responseData: Data, sw1: UInt8, sw2: UInt8) {
        self.responseData = responseData
        self.sw1 = sw1
        self.sw2 = sw2
    }

    public var hexString: String {
        responseData.map { String(format: "%02hhX", $0) }.joined()
    }

    public var statusDescription: String {
        switch statusWord {
        case 0x9000: return "Sukses (0x9000)"
        case 0x6A82: return "File / Aplikasi tidak ditemukan (0x6A82)"
        case 0x6982: return "Status keamanan tidak terpenuhi (0x6982)"
        case 0x6A86: return "Parameter P1-P2 tidak valid (0x6A86)"
        case 0x6700: return "Panjang data salah (0x6700)"
        default:
            return String(format: "Status: 0x%04X", statusWord)
        }
    }
}
