import SwiftUI

/// Tampilan Struk Belanja Belanja (Thermal Receipt) untuk transaksi e-money
/// Mendukung mode cetak semua transaksi maupun 1 transaksi tunggal terpilih
public struct ReceiptView: View {
    public let cardAlias: String
    public let issuerName: String
    public let maskedNumber: String?
    public let balance: Int?
    public let scanDate: Date
    public let transactions: [TransactionRecord]
    public let selectedSingleTransaction: TransactionRecord?

    public init(
        cardAlias: String,
        issuerName: String,
        maskedNumber: String?,
        balance: Int?,
        scanDate: Date,
        transactions: [TransactionRecord],
        selectedSingleTransaction: TransactionRecord? = nil
    ) {
        self.cardAlias = cardAlias
        self.issuerName = issuerName
        self.maskedNumber = maskedNumber
        self.balance = balance
        self.scanDate = scanDate
        self.transactions = transactions
        self.selectedSingleTransaction = selectedSingleTransaction
    }

    private var isSingleMode: Bool {
        selectedSingleTransaction != nil
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Jagged top edge
            HStack(spacing: 4) {
                ForEach(0..<18, id: \.self) { _ in
                    Circle()
                        .fill(Color(white: 0.95))
                        .frame(width: 14, height: 14)
                        .offset(y: -7)
                }
            }
            .clipped()
            .frame(height: 8)

            VStack(spacing: 12) {
                // Header Toko / Struk
                VStack(spacing: 4) {
                    Text("TAPEMONEY")
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .tracking(3)

                    Text(isSingleMode ? "BUKTI TRANSAKSI E-MONEY" : "STRUK CATATAN TRANSAKSI E-MONEY")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)

                    Text(isSingleMode ? "TRANSAKSI TUNGGAL • OFFLINE CHIP" : "OFFLINE CHIP READER")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)

                dashedDivider

                // Info Kartu & Waktu
                VStack(spacing: 4) {
                    receiptRow(left: "WAKTU CETAK", right: formattedDateTime(scanDate))
                    receiptRow(left: "KARTU", right: cardAlias.uppercased())
                    receiptRow(left: "PENERBIT", right: issuerName.uppercased())
                    if let masked = maskedNumber {
                        receiptRow(left: "NO. KARTU", right: masked)
                    }
                    receiptRow(left: "STATUS CHIP", right: "TERVERIFIKASI")
                }

                dashedDivider

                if let singleTx = selectedSingleTransaction {
                    // MODE: 1 TRANSAKSI TERPILIH
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DETAIL TRANSAKSI TERPILIH")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.secondary)

                        dottedDivider

                        receiptRow(left: "TANGGAL & JAM", right: formattedTxTime(singleTx.transactionDate))
                        receiptRow(left: "JENIS", right: (singleTx.transactionType ?? "Pembayaran").uppercased())
                        if let loc = singleTx.merchantLocation, !loc.isEmpty {
                            receiptRow(left: "LOKASI / TERMINAL", right: loc.uppercased())
                        }

                        dottedDivider

                        HStack {
                            Text("NOMINAL")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                            Spacer()
                            Text(singleTx.formattedAmount)
                                .font(.system(size: 18, weight: .black, design: .monospaced))
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    // MODE: SEMUA TRANSAKSI
                    HStack {
                        Text("TGL/JAM • KETERANGAN")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                        Spacer()
                        Text("NOMINAL")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }

                    dottedDivider

                    if transactions.isEmpty {
                        VStack(spacing: 4) {
                            Text("TIDAK ADA MUTASI TERCATAT DI CHIP")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text("(Data transaksi chip kosong atau telah di-clear)")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(transactions) { tx in
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(formattedTxTime(tx.transactionDate))
                                                .font(.system(size: 9, design: .monospaced))
                                                .foregroundColor(.secondary)

                                            Text((tx.transactionType ?? "Pembayaran").uppercased())
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))

                                            if let loc = tx.merchantLocation, !loc.isEmpty {
                                                Text(loc)
                                                    .font(.system(size: 10, design: .monospaced))
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }

                                        Spacer()

                                        Text(tx.formattedAmount)
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    }
                                }
                            }
                        }
                    }
                }

                dashedDivider

                // Ringkasan Total & Sisa Saldo
                VStack(spacing: 5) {
                    if !isSingleMode {
                        let totalPengeluaran = transactions
                            .compactMap { $0.amount }
                            .filter { $0 > 0 }
                            .reduce(0, +)

                        receiptRow(left: "JML TRANSAKSI", right: "\(transactions.count) RECORD")
                        receiptRow(left: "TTL PENGELUARAN", right: CardProfile.formatCurrency(totalPengeluaran))
                        dottedDivider
                    }

                    HStack {
                        Text("SISA SALDO KARTU")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                        Spacer()
                        Text(balance != nil ? CardProfile.formatCurrency(balance!) : "Rp --")
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                    }
                }

                dashedDivider

                // Footer Barcode Aesthetic
                VStack(spacing: 6) {
                    HStack(spacing: 2) {
                        ForEach(0..<42, id: \.self) { i in
                            Rectangle()
                                .fill(Color.black.opacity(i % 3 == 0 ? 0.9 : (i % 2 == 0 ? 0.6 : 0.3)))
                                .frame(width: (i % 4 == 0) ? 3 : (i % 2 == 0 ? 2 : 1), height: 32)
                        }
                    }

                    Text(isSingleMode ? "* BUKTI TRANSAKSI TUNGGAL OFFLINE *" : "* TAPEMONEY - SIMPAN STRUK INI *")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .tracking(1.2)

                    Text("DISIMPAN LOKAL DI IPHONE")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 20)
            .background(Color.white)

            // Jagged bottom edge
            HStack(spacing: 4) {
                ForEach(0..<18, id: \.self) { _ in
                    Circle()
                        .fill(Color(white: 0.95))
                        .frame(width: 14, height: 14)
                        .offset(y: 7)
                }
            }
            .clipped()
            .frame(height: 8)
        }
        .frame(width: 320)
        .background(Color.white)
        .foregroundColor(Color.black)
        .cornerRadius(4)
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
    }

    private var dashedDivider: some View {
        Text(String(repeating: "- ", count: 20))
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(Color.gray.opacity(0.6))
            .lineLimit(1)
    }

    private var dottedDivider: some View {
        Text(String(repeating: ". ", count: 24))
            .font(.system(size: 9, design: .monospaced))
            .foregroundColor(Color.gray.opacity(0.4))
            .lineLimit(1)
    }

    private func receiptRow(left: String, right: String) -> some View {
        HStack {
            Text(left)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
            Spacer()
            Text(right)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
        }
    }

    private func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }

    private func formattedTxTime(_ date: Date?) -> String {
        guard let date = date else { return "--/--/---- --:--" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        return formatter.string(from: date)
    }
}
