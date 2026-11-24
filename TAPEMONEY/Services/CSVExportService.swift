import Foundation

/// Layanan ekspor data scan dan transaksi ke format CSV untuk iOS share sheet (FR-013)
public final class CSVExportService {
    public static func generateCSV(from scans: [ScanRecord]) -> URL? {
        var csvString = "Waktu Scan,Alias Kartu,Penerbit,Tipe Kartu,Nomor Terproteksi,Saldo (IDR),Status Saldo,Status Riwayat,Tipe Transaksi,Nominal Transaksi (IDR),Lokasi/Merchant\n"

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Jakarta")

        for scan in scans {
            let scanTime = dateFormatter.string(from: scan.scannedAt)
            let alias = escapeCSV(scan.cardProfile?.alias ?? "Kartu")
            let issuer = escapeCSV(scan.cardProfile?.issuer.displayName ?? "-")
            let cardType = escapeCSV(scan.cardProfile?.cardType ?? "-")
            let masked = escapeCSV(scan.cardProfile?.maskedCardIdentifier ?? "-")
            let balance = scan.balance != nil ? "\(scan.balance!)" : "-"
            let balStatus = scan.balanceStatus.localizedTitle
            let histStatus = scan.historyStatus.localizedTitle

            if scan.transactions.isEmpty {
                csvString += "\(scanTime),\(alias),\(issuer),\(cardType),\(masked),\(balance),\(balStatus),\(histStatus),-,-,-\n"
            } else {
                for tx in scan.transactions {
                    let txType = escapeCSV(tx.transactionType ?? "-")
                    let txAmount = tx.amount != nil ? "\(tx.amount!)" : "-"
                    let merchant = escapeCSV(tx.merchantLocation ?? "-")
                    csvString += "\(scanTime),\(alias),\(issuer),\(cardType),\(masked),\(balance),\(balStatus),\(histStatus),\(txType),\(txAmount),\(merchant)\n"
                }
            }
        }

        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("TAPEMONEY_Riwayat_\(Int(Date().timeIntervalSince1970)).csv")

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Gagal menulis file CSV: \(error)")
            return nil
        }
    }

    private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let replaced = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(replaced)\""
        }
        return value
    }
}
