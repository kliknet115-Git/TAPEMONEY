import Foundation

/// Kontrak protokol adapter kartu uang elektronik (sesuai Bab 6.4 PRD)
public protocol EMoneyCardAdapter: Sendable {
    var issuer: CardIssuer { get }
    var issuerName: String { get }
    var adapterVersion: String { get }

    /// Memeriksa apakah tag yang terdeteksi cocok dengan karakteristik kartu ini
    func canHandle(_ tag: DetectedNFCTag) -> Bool

    /// Membaca info kartu (saldo & transaksi yang diizinkan/tersedia secara legal dan aman)
    func readCardInfo(from tag: DetectedNFCTag) async throws -> CardReadResult
}
