import SwiftUI
import SwiftData

/// Tampilan Beranda Utama TAPEMONEY (Bab 10.1 PRD)
public struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CardProfile.lastScannedAt, order: .reverse) private var savedCards: [CardProfile]
    @Query(sort: \ScanRecord.scannedAt, order: .reverse) private var recentScans: [ScanRecord]

    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var nfcCoordinator: NFCScanCoordinator
    @EnvironmentObject private var repository: CardDataRepository

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // NFC Hardware Status Banner
                    NFCStatusBanner(isAvailable: nfcCoordinator.isNFCAvailable)
                        .padding(.horizontal)

                    // Hero Scan Tap Button Card
                    heroScanButton

                    // Metrik Dashboard
                    quickMetricsSection

                    // Kartu Terakhir Discan / Carousel
                    savedCardsSection

                    // Riwayat Terakhir Singkat
                    recentScansSection
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("TAPEMONEY")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Section("Simulasi Kartu (Preview)") {
                            Button {
                                viewModel.selectedSimulationIssuer = .bca
                                viewModel.showSimulatedScanSheet = true
                            } label: {
                                Label("Simulasi Flazz Gen 2", systemImage: "creditcard")
                            }

                            Button {
                                viewModel.selectedSimulationIssuer = .mandiri
                                viewModel.showSimulatedScanSheet = true
                            } label: {
                                Label("Simulasi Mandiri e-money", systemImage: "creditcard")
                            }

                            Button {
                                viewModel.selectedSimulationIssuer = .bni
                                viewModel.showSimulatedScanSheet = true
                            } label: {
                                Label("Simulasi BNI TapCash", systemImage: "creditcard")
                            }

                            Button {
                                viewModel.selectedSimulationIssuer = .bri
                                viewModel.showSimulatedScanSheet = true
                            } label: {
                                Label("Simulasi BRI BRIZZI", systemImage: "creditcard")
                            }
                        }

                        Button {
                            repository.seedPreviewDataIfEmpty()
                        } label: {
                            Label("Muat Data Contoh", systemImage: "sparkles")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                    }
                }
            }
            .sheet(isPresented: $viewModel.showScanSheet) {
                ScanSheetView(simulationIssuer: nil)
            }
            .sheet(isPresented: $viewModel.showSimulatedScanSheet) {
                ScanSheetView(simulationIssuer: viewModel.selectedSimulationIssuer)
            }
        }
    }

    // MARK: - Hero Tap Button
    private var heroScanButton: some View {
        Button {
            viewModel.showScanSheet = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.08, green: 0.38, blue: 0.94), Color(red: 0.02, green: 0.22, blue: 0.70)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(red: 0.08, green: 0.38, blue: 0.94).opacity(0.4), radius: 16, x: 0, y: 8)

                VStack(spacing: 16) {
                    // Animated Radar NFC Icon
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            .frame(width: 80, height: 80)

                        Circle()
                            .stroke(Color.white.opacity(0.35), lineWidth: 2)
                            .frame(width: 62, height: 62)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 48, height: 48)

                        Image(systemName: "wave.3.forward.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color(red: 0.08, green: 0.38, blue: 0.94))
                    }

                    VStack(spacing: 4) {
                        Text("SCAN KARTU SEKARANG")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(1.2)

                        Text("Tempelkan kartu e-money di belakang iPhone")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }

                    // Card Issuer Logos Pill
                    HStack(spacing: 12) {
                        ForEach(["Flazz", "e-money", "TapCash", "BRIZZI"], id: \.self) { card in
                            Text(card)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.vertical, 26)
                .padding(.horizontal, 20)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    // MARK: - Quick Metrics
    private var quickMetricsSection: some View {
        HStack(spacing: 12) {
            let totalCards = savedCards.count
            let totalBalance = savedCards.compactMap { $0.latestBalance }.reduce(0, +)

            MetricCardView(
                title: "Kartu Tersimpan",
                value: "\(totalCards)",
                subtitle: "Offline di iPhone",
                iconName: "creditcard.fill",
                iconColor: .blue
            )

            MetricCardView(
                title: "Total Saldo Terbaca",
                value: CardProfile.formatCurrency(totalBalance),
                subtitle: "\(savedCards.filter { $0.latestBalance != nil }.count) kartu aktif",
                iconName: "banknote.fill",
                iconColor: .green
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Saved Cards
    private var savedCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Kartu Terakhir")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                NavigationLink(destination: CardListView()) {
                    Text("Lihat Semua (\(savedCards.count))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            if savedCards.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "creditcard.and.123")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Belum ada kartu yang disimpan")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("Tekan tombol Scan di atas untuk membaca kartu pertama Anda.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(18)
                .padding(.horizontal)
            } else {
                TabView {
                    ForEach(savedCards.prefix(5)) { card in
                        NavigationLink(destination: CardDetailView(card: card)) {
                            CardVisualView(
                                issuer: card.issuer,
                                alias: card.alias,
                                maskedNumber: card.maskedCardIdentifier,
                                balance: card.latestBalance,
                                cardType: card.cardType,
                                cardGeneration: card.cardGeneration,
                                lastScanned: card.lastScannedAt
                            )
                            .padding(.horizontal, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: 225)
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Recent Scans
    private var recentScansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Aktivitas Scan")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                NavigationLink(destination: HistoryView()) {
                    Text("Riwayat Lengkap")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            if recentScans.isEmpty {
                VStack(spacing: 6) {
                    Text("Belum ada riwayat scan")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(14)
                .padding(.horizontal)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentScans.prefix(3)) { scan in
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(scan.cardProfile?.issuer.primaryColor.opacity(0.12) ?? Color.gray.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(scan.cardProfile?.issuer.primaryColor ?? .gray)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(scan.cardProfile?.alias ?? "Kartu")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(formattedDate(scan.scannedAt))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(scan.formattedBalance)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(scan.balanceStatus == .success ? .primary : .secondary)

                                StatusPillView(status: scan.balanceStatus)
                                    .scaleEffect(0.85)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal)
            }
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
