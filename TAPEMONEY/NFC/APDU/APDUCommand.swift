import Foundation
import CoreNFC

/// Helper pembentuk dan penyusun APDU (Application Protocol Data Unit) ISO 7816
public struct APDUCommand: Sendable {
    public let cla: UInt8
    public let ins: UInt8
    public let p1: UInt8
    public let p2: UInt8
    public let data: Data?
    public let le: Int?

    public init(cla: UInt8, ins: UInt8, p1: UInt8, p2: UInt8, data: Data? = nil, le: Int? = nil) {
        self.cla = cla
        self.ins = ins
        self.p1 = p1
        self.p2 = p2
        self.data = data
        self.le = le
    }

    /// Konversi ke `NFCISO7816APDU` native Core NFC
    public func toNFCISO7816APDU() -> NFCISO7816APDU? {
        NFCISO7816APDU(
            instructionClass: cla,
            instructionCode: ins,
            p1Parameter: p1,
            p2Parameter: p2,
            data: data ?? Data(),
            expectedResponseLength: le ?? -1
        )
    }

    /// Perintah standar ISO 7816-4: SELECT FILE / APPLICATION BY AID
    public static func selectAID(_ aid: Data) -> APDUCommand {
        APDUCommand(cla: 0x00, ins: 0xA4, p1: 0x04, p2: 0x00, data: aid, le: 0x00)
    }

    /// Helper parse hex string menjadi Data byte array
    public static func dataFromHex(_ hex: String) -> Data {
        let cleaned = hex.replacingOccurrences(of: " ", with: "")
        var data = Data()
        var index = cleaned.startIndex
        while index < cleaned.endIndex {
            let nextIndex = cleaned.index(index, offsetBy: 2, limitedBy: cleaned.endIndex) ?? cleaned.endIndex
            let byteString = cleaned[index..<nextIndex]
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            }
            index = nextIndex
        }
        return data
    }
}
