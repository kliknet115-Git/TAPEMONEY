import SwiftUI
import SwiftData

/// Halaman Riwayat Scan Kartu Offline (Bab 10.5 PRD)
/// Mendukung ekspor Struk Belanja Belanja (1 Transaksi Terpilih atau Semua) ke PNG / PDF
public struct HistoryView: View {
    @Query(sort: \ScanRecord.scannedAt, order: .reverse) private var scans: [ScanRecord]
    @EnvironmentObject private var repository: CardDataRepository

    @State private var selectedFilter: CardIssuer? = nil
    @State private var selectedScanForReceipt: ScanRecord? = nil
    @State private var showReceiptSheet: Bool = false
    @State private var shareURL: URL? = nil
    @State private var showShareSheet: Bool = false

    private var filteredScans: [ScanRecord] {
        if let filter = selectedFilter {
            return scans.filter { $0.cardProfile?.issuer == filter }
        }
        return scans
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Warning Notice (Bab 10.5 PRD)
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                    Text("Catatan: Data di bawah adalah arsip hasil pembacaan lokal. Ketuk kartu mana saja untuk mencetak/membagikan struk transaksi (1 transaksi atau seluruhnya).")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 6)

                // Filter Kartu Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterButton(title: "Semua", issuer: nil)
                        ForEach(CardIssuer.allCases.filter { $0 != .unknown }) { issuer in
                            filterButton(title: issuer.brandName, issuer: issuer)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // List Scan Records
                List {
                    if filteredScans.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary)
                            Text("Tidak ada riwayat untuk filter ini")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(filteredScans) { scan in
                            Button {
                                selectedScanForReceipt = scan
                                showReceiptSheet = true
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill(scan.cardProfile?.issuer.primaryColor.opacity(0.12) ?? Color.gray.opacity(0.12))
                                                .frame(width: 38, height: 38)
                                            Image(systemName: "creditcard.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(scan.cardProfile?.issuer.primaryColor ?? .blue)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(scan.cardProfile?.alias ?? "Kartu")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(.primary)
                                            Text("\(scan.cardProfile?.issuer.brandName ?? "") • \(formattedDate(scan.scannedAt))")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 3) {
                                            Text(scan.formattedBalance)
                                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                                .foregroundColor(.primary)
                                            StatusPillView(status: scan.balanceStatus)
                                                .scaleEffect(0.8)
                                        }
                                    }

                                    if !scan.transactions.isEmpty {
                                        HStack {
                                            Text("Klik untuk cetak struk (\(scan.transactions.count) record)")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.blue)
                                            Spacer()
                                            Image(systemName: "doc.text.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.08))
                                        .cornerRadius(6)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    try? repository.deleteScanRecord(scan)
                                } label: {
                                    Label("Hapus", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Riwayat Scan")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedScanForReceipt = filteredScans.first ?? scans.first
                        showReceiptSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .disabled(scans.isEmpty)
                }
            }
            .sheet(isPresented: $showReceiptSheet) {
                if let scan = selectedScanForReceipt {
                    ReceiptExportModalView(
                        scan: scan,
                        onShareURL: { url in
                            self.shareURL = url
                            self.showShareSheet = true
                        }
                    )
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    private func filterButton(title: String, issuer: CardIssuer?) -> some View {
        let isSelected = selectedFilter == issuer
        return Button {
            selectedFilter = issuer
        } label: {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(18)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Modal Lembar Struk Belanja Belanja & Pilihan Ekspor PNG/PDF
/// Dilengkapi opsi beralih antara "1 Transaksi Terpilih" atau "Semua Transaksi"
struct ReceiptExportModalView: View {
    @Environment(\.dismiss) private var dismiss
    public let scan: ScanRecord
    public let onShareURL: (URL) -> Void

    @State private var exportMode: Int = 0 // 0 = 1 Transaksi Saja, 1 = Semua Transaksi
    @State private var selectedTxIndex: Int = 0

    private var selectedSingleTx: TransactionRecord? {
        guard !scan.transactions.isEmpty, selectedTxIndex < scan.transactions.count else { return nil }
        return scan.transactions[selectedTxIndex]
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Mode Selector (1 Transaksi vs Semua)
                    if !scan.transactions.isEmpty {
                        Picker("Mode Struk", selection: $exportMode) {
                            Text("1 Transaksi Terpilih").tag(0)
                            Text("Semua Transaksi (\(scan.transactions.count))").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        if exportMode == 0 && scan.transactions.count > 1 {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Pilih Transaksi:")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.secondary)

                                Picker("Pilih Transaksi", selection: $selectedTxIndex) {
                                    ForEach(0..<scan.transactions.count, id: \.self) { idx in
                                        let tx = scan.transactions[idx]
                                        Text("\(tx.transactionType ?? "Transaksi") - \(tx.formattedAmount)").tag(idx)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Struk Component Preview
                    ReceiptView(
                        cardAlias: scan.cardProfile?.alias ?? "Kartu",
                        issuerName: scan.cardProfile?.issuer.displayName ?? "e-Money",
                        maskedNumber: scan.cardProfile?.maskedCardIdentifier,
                        balance: scan.balance,
                        scanDate: scan.scannedAt,
                        transactions: scan.transactions,
                        selectedSingleTransaction: (exportMode == 0) ? selectedSingleTx : nil
                    )

                    // Tombol Ekspor
                    VStack(spacing: 12) {
                        Button {
                            let single = (exportMode == 0) ? selectedSingleTx : nil
                            if let url = ReceiptGeneratorService.renderReceiptToPNG(
                                cardAlias: scan.cardProfile?.alias ?? "Kartu",
                                issuerName: scan.cardProfile?.issuer.displayName ?? "e-Money",
                                maskedNumber: scan.cardProfile?.maskedCardIdentifier,
                                balance: scan.balance,
                                scanDate: scan.scannedAt,
                                transactions: scan.transactions,
                                singleTransaction: single
                            ) {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onShareURL(url)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text("Bagikan sebagai Gambar (PNG)")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }

                        Button {
                            let single = (exportMode == 0) ? selectedSingleTx : nil
                            if let url = ReceiptGeneratorService.renderReceiptToPDF(
                                cardAlias: scan.cardProfile?.alias ?? "Kartu",
                                issuerName: scan.cardProfile?.issuer.displayName ?? "e-Money",
                                maskedNumber: scan.cardProfile?.maskedCardIdentifier,
                                balance: scan.balance,
                                scanDate: scan.scannedAt,
                                transactions: scan.transactions,
                                singleTransaction: single
                            ) {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onShareURL(url)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "doc.richtext.fill")
                                Text("Bagikan sebagai Dokumen (PDF)")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(exportMode == 0 ? "Struk 1 Transaksi" : "Struk Semua Transaksi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tutup") { dismiss() }
                }
            }
        }
    }
}
