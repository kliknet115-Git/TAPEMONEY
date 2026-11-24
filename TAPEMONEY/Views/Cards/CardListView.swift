import SwiftUI
import SwiftData

/// Halaman Manajemen Daftar Kartu (Bab 10.4 PRD)
public struct CardListView: View {
    @Query(sort: \CardProfile.createdAt, order: .reverse) private var cards: [CardProfile]
    @EnvironmentObject private var repository: CardDataRepository
    @StateObject private var viewModel: CardListViewModel

    public init() {
        // ViewModel di-init kemudian diikat dengan repository di onAppear/modifier
        _viewModel = StateObject(wrappedValue: CardListViewModel(repository: CardDataRepository(modelContext: try! ModelContext(ModelContainer(for: CardProfile.self)))))
    }

    public var body: some View {
        List {
            if cards.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "creditcard")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text("Belum ada kartu tersimpan")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Pindai kartu e-money Anda untuk menyimpannya di sini.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .listRowBackground(Color.clear)
            } else {
                ForEach(cards) { card in
                    NavigationLink(destination: CardDetailView(card: card)) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: card.issuer.gradientColors,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 52, height: 36)

                                Image(systemName: "wave.3.forward")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(card.alias)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)

                                HStack(spacing: 6) {
                                    Text(card.issuer.brandName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(card.issuer.primaryColor)

                                    if let gen = card.cardGeneration {
                                        Text("• \(gen)")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(card.formattedBalance)
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                    .foregroundColor(.primary)

                                if let date = card.lastScannedAt {
                                    Text(formattedShortDate(date))
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteCard(card)
                        } label: {
                            Label("Hapus", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Kartu Saya")
    }

    private func deleteCard(_ card: CardProfile) {
        try? repository.deleteCard(profile: card)
    }

    private func formattedShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

/// Detail Profil Kartu dan Riwayat Scannya
public struct CardDetailView: View {
    @Bindable public var card: CardProfile
    @EnvironmentObject private var repository: CardDataRepository
    @State private var isEditingAlias: Bool = false
    @State private var aliasInput: String = ""

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Card Visual
                CardVisualView(
                    issuer: card.issuer,
                    alias: card.alias,
                    maskedNumber: card.maskedCardIdentifier,
                    balance: card.latestBalance,
                    cardType: card.cardType,
                    cardGeneration: card.cardGeneration,
                    lastScanned: card.lastScannedAt
                )
                .padding(.horizontal)

                // Quick Info Box
                VStack(spacing: 12) {
                    HStack {
                        Text("Alias Kartu")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(card.alias)
                            .font(.system(size: 15, weight: .bold))
                        Button {
                            aliasInput = card.alias
                            isEditingAlias = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }

                    Divider()

                    HStack {
                        Text("Penerbit")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(card.issuer.displayName)
                            .font(.system(size: 15, weight: .semibold))
                    }

                    Divider()

                    HStack {
                        Text("Nomor Kartu (Masked)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(card.maskedCardIdentifier ?? "-")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                    }

                    Divider()

                    HStack {
                        Text("Total Sesi Scan")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(card.scans.count) kali")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal)

                // Log Transaksi dari scan terakhir
                if let lastScan = card.scans.sorted(by: { $0.scannedAt > $1.scannedAt }).first, !lastScan.transactions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Catatan Transaksi Terakhir di Chip")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            ForEach(lastScan.transactions) { tx in
                                TransactionRowView(
                                    sequence: tx.recordSequence,
                                    date: tx.transactionDate,
                                    amount: tx.amount,
                                    type: tx.transactionType ?? "Pembayaran",
                                    merchant: tx.merchantLocation
                                )
                                .padding(.horizontal, 14)

                                if tx.id != lastScan.transactions.last?.id {
                                    Divider().padding(.leading, 64)
                                }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(card.alias)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Ubah Alias Kartu", isPresented: $isEditingAlias) {
            TextField("Nama Kartu", text: $aliasInput)
            Button("Simpan") {
                try? repository.updateCardAlias(profile: card, newAlias: aliasInput)
            }
            Button("Batal", role: .cancel) {}
        }
    }
}
