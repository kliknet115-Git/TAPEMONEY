import SwiftUI
import UIKit

/// Layanan untuk mengekspor struk belanja ke format PNG atau PDF (iOS Native)
@MainActor
public final class ReceiptGeneratorService {

    /// Ekspor Tampilan Struk ke file gambar PNG (semua atau 1 transaksi tunggal)
    public static func renderReceiptToPNG(
        cardAlias: String,
        issuerName: String,
        maskedNumber: String?,
        balance: Int?,
        scanDate: Date,
        transactions: [TransactionRecord],
        singleTransaction: TransactionRecord? = nil
    ) -> URL? {
        let receiptView = ReceiptView(
            cardAlias: cardAlias,
            issuerName: issuerName,
            maskedNumber: maskedNumber,
            balance: balance,
            scanDate: scanDate,
            transactions: transactions,
            selectedSingleTransaction: singleTransaction
        )
        .padding(16)
        .background(Color(white: 0.94))

        let renderer = ImageRenderer(content: receiptView)
        renderer.scale = 3.0 // High resolution Retina

        guard let uiImage = renderer.uiImage else { return nil }
        guard let data = uiImage.pngData() else { return nil }

        let prefix = singleTransaction != nil ? "Struk_Tunggal" : "Struk_Riwayat"
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)_TAPEMONEY_\(Int(Date().timeIntervalSince1970)).png")

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Gagal menulis gambar struk PNG: \(error)")
            return nil
        }
    }

    /// Ekspor Tampilan Struk ke dokumen PDF (semua atau 1 transaksi tunggal)
    public static func renderReceiptToPDF(
        cardAlias: String,
        issuerName: String,
        maskedNumber: String?,
        balance: Int?,
        scanDate: Date,
        transactions: [TransactionRecord],
        singleTransaction: TransactionRecord? = nil
    ) -> URL? {
        let receiptView = ReceiptView(
            cardAlias: cardAlias,
            issuerName: issuerName,
            maskedNumber: maskedNumber,
            balance: balance,
            scanDate: scanDate,
            transactions: transactions,
            selectedSingleTransaction: singleTransaction
        )
        .padding(16)
        .background(Color(white: 0.94))

        let renderer = ImageRenderer(content: receiptView)
        let prefix = singleTransaction != nil ? "Struk_Tunggal" : "Struk_Riwayat"
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)_TAPEMONEY_\(Int(Date().timeIntervalSince1970)).pdf")

        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let pdf = CGContext(tempURL as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }

        return FileManager.default.fileExists(atPath: tempURL.path) ? tempURL : nil
    }
}
