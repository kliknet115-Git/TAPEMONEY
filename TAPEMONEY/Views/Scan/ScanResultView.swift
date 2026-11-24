import SwiftUI

/// Halaman Hasil Scan Kartu (Bab 10.3 PRD)
/// Memenuhi FR-006, FR-007, FR-008, FR-011, FR-015
public struct ScanResultView: View {
    public let result: CardReadResult
    public let onDismiss: () -> Void

    @EnvironmentObject private var repository: CardDataRepository
    @State private var cardAlias: String = ""
    @State private var isSaved: Bool = false
    @State private var saveErrorMessage: String? = nil
    @State private var showHistorySheet: Bool = false

    public init(result: CardReadResult, onDismiss: @escaping () -> Void) {
        self.result = result
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Card Visual Representation
                CardVisualView(
                    issuer: result.issuer,
                    alias: cardAlias.isEmpty ? "\(result.issuer.brandName) Scan" : cardAlias,
                    maskedNumber: result.maskedIdentifier,
                    balance: result.balance,
                    cardType: result.cardType,
                    cardGeneration: result.cardGeneration,
                    lastScanned: Date()
                )
                .padding(.horizontal)

                // Large Balance Display (FR-006)
                VStack(spacing: 6) {
                    Text("SALDO TERVERIFIKASI")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.5)

                    if result.balanceStatus == .success, let balance = result.balance {
                        Text(CardProfile.formatCurrency(balance))
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                    } else {
                        Text("Tidak Tersedia")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    // Timestamp Pembacaan (Bukan timestamp transaksi)
                    Text("Dibaca pada: \(formattedCurrentDate())")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                // Dual Status Pills (FR-011: Saldo dan Histori terpisah)
                HStack(spacing: 12) {
                    StatusPillView(status: result.balanceStatus, labelPrefix: "Saldo")
                    StatusPillView(status: result.historyStatus, labelPrefix: "Riwayat")
                }

                // Input Alias Kartu (FR-009)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Beri Nama / Alias Kartu")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)

                    HStack {
                        Image(systemName: "pencil")
                            .foregroundColor(.secondary)
                        TextField("Contoh: Kartu Tol Pribadi", text: $cardAlias)
                            .font(.system(size: 15))
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // Transactions List (FR-007)
                transactionsSection

                // Diagnostik / Technical Note
                if let diagnostic = result.rawDiagnosticMessage {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text(diagnostic)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Action Buttons (Simpan, Scan Ulang, Selesai)
                actionButtonsSection
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Hasil Scan")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            cardAlias = "\(result.issuer.brandName) \(result.cardGeneration ?? "")".trimmingCharacters(in: .whitespaces)
        }
    }

    // MARK: - Transactions Section
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Riwayat Pada Kartu")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("Maksimal transaksi yang tersimpan di chip fisik kartu")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()

                if !result.transactions.isEmpty {
                    Text("\(result.transactions.count) Record")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal)

            if result.transactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("Tidak ada riwayat transaksi pada chip")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("Kartu ini tidak menyediakan log transaksi terbuka atau data histori telah dibersihkan oleh terminal bank.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(result.transactions) { tx in
                        TransactionRowView(
                            sequence: tx.sequence,
                            date: tx.date,
                            amount: tx.amount,
                            type: tx.type,
                            merchant: tx.merchantOrTerminal
                        )
                        .padding(.horizontal, 14)

                        if tx.id != result.transactions.last?.id {
                            Divider()
                                .padding(.leading, 64)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if isSaved {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Hasil scan berhasil disimpan secara lokal!")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                }
                .padding(.vertical, 8)
            } else {
                Button {
                    saveScan()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("Simpan ke Kartu Saya")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
            }

            if let error = saveErrorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }

            Button {
                onDismiss()
            } label: {
                Text("Selesai")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func saveScan() {
        do {
            try repository.saveScanResult(result, customAlias: cardAlias)
            isSaved = true
            saveErrorMessage = nil
        } catch {
            saveErrorMessage = "Gagal menyimpan: \(error.localizedDescription)"
        }
    }

    private func formattedCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}
