import SwiftUI
import SwiftData

/// Halaman Riwayat Scan Kartu Offline (Bab 10.5 PRD)
/// Memenuhi FR-010, FR-013, FR-014
public struct HistoryView: View {
    @Query(sort: \ScanRecord.scannedAt, order: .reverse) private var scans: [ScanRecord]
    @EnvironmentObject private var repository: CardDataRepository

    @State private var selectedFilter: CardIssuer? = nil
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
                // Warning Notice (Bab 10.5 PRD): Data lama bukan saldo real-time
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                    Text("Catatan: Data di bawah adalah arsip hasil pembacaan lokal. Saldo dan transaksi real-time didapatkan saat kartu di-tap ulang.")
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
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(scan.cardProfile?.alias ?? "Kartu")
                                            .font(.system(size: 16, weight: .bold))
                                        Text("\(scan.cardProfile?.issuer.brandName ?? "") • \(formattedDate(scan.scannedAt))")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 3) {
                                        Text(scan.formattedBalance)
                                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                                        StatusPillView(status: scan.balanceStatus)
                                            .scaleEffect(0.8)
                                    }
                                }

                                if !scan.transactions.isEmpty {
                                    Text("\(scan.transactions.count) transaksi tersimpan di scan ini")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
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
                        exportCSV()
                    } label: {
                        Label("Ekspor CSV", systemImage: "square.and.arrow.up")
                    }
                    .disabled(scans.isEmpty)
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

    private func exportCSV() {
        if let url = CSVExportService.generateCSV(from: scans) {
            self.shareURL = url
            self.showShareSheet = true
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

/// UIActivityViewController wrapper untuk iOS Share Sheet (FR-013)
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
