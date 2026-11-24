import SwiftUI
import SwiftData

/// Halaman Pengaturan, Diagnostik NFC, dan Kebijakan Privasi (Bab 10.6 PRD)
public struct SettingsView: View {
    @EnvironmentObject private var repository: CardDataRepository
    @EnvironmentObject private var nfcCoordinator: NFCScanCoordinator
    @StateObject private var viewModel: SettingsViewModel

    public init() {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(
            repository: CardDataRepository(modelContext: ModelContext(try! ModelContainer(for: CardProfile.self))),
            nfcCoordinator: NFCScanCoordinator()
        ))
    }

    public var body: some View {
        NavigationStack {
            List {
                // Section 1: Informasi Sensor NFC iPhone
                Section("Sensor & Hardware") {
                    HStack {
                        Label("Status Core NFC", systemImage: "wave.3.forward.circle.fill")
                            .foregroundColor(.blue)
                        Spacer()
                        Text(nfcCoordinator.isNFCAvailable ? "Didukung" : "Tidak Tersedia")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(nfcCoordinator.isNFCAvailable ? .green : .red)
                    }

                    HStack {
                        Label("Metode Pembacaan", systemImage: "tag.fill")
                            .foregroundColor(.purple)
                        Spacer()
                        Text("NFCTagReaderSession (ISO 7816)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                // Section 2: Matriks Kompatibilitas Kartu
                Section("Target Kartu & Kompatibilitas") {
                    NavigationLink(destination: CompatibilityMatrixView(matrix: viewModel.compatibilityMatrix)) {
                        Label("Tabel Matriks Kartu (PRD v2.0)", systemImage: "tablecells.badge.ellipsis")
                    }
                }

                // Section 3: Privasi dan Keamanan (Bab 12 PRD)
                Section("Privasi & Keamanan Data") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                            Text("100% Offline & Read-Only")
                                .font(.system(size: 14, weight: .bold))
                        }
                        Text("Aplikasi TAPEMONEY tidak mengirim data kartu, saldo, atau transaksi ke server eksternal mana pun. Seluruh data tersimpan terenkripsi di dalam sandbox lokal iPhone Anda.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    HStack {
                        Label("Mode Operasi", systemImage: "eye.fill")
                        Spacer()
                        Text("Hanya Baca (Read-Only)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Koneksi Server", systemImage: "wifi.slash")
                        Spacer()
                        Text("Tidak Ada (Zero Cloud)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                // Section 4: Data Management & Reset (FR-012)
                Section("Manajemen Data Lokal") {
                    Button(role: .destructive) {
                        viewModel.showResetConfirmation = true
                    } label: {
                        Label("Hapus Seluruh Data & Riwayat", systemImage: "trash.fill")
                            .foregroundColor(.red)
                    }
                }

                // Section 5: Tentang Aplikasi
                Section("Tentang Aplikasi") {
                    HStack {
                        Text("Nama Aplikasi")
                        Spacer()
                        Text("TAPEMONEY")
                            .font(.system(size: 14, weight: .bold))
                    }

                    HStack {
                        Text("Versi Produk")
                        Spacer()
                        Text("2.0.0 (MVP Native)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Target Framework")
                        Spacer()
                        Text("SwiftUI • Core NFC • SwiftData")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Pengaturan")
            .confirmationDialog(
                "Hapus Seluruh Data?",
                isPresented: $viewModel.showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Hapus Semua Data", role: .destructive) {
                    try? repository.resetAllData()
                }
                Button("Batal", role: .cancel) {}
            } message: {
                Text("Tindakan ini akan menghapus semua profil kartu tersimpan, riwayat scan, dan catatan transaksi lokal di iPhone Anda secara permanen.")
            }
        }
    }
}

/// Tampilan Matriks Kompatibilitas 4 Kartu (Bab 5 PRD)
public struct CompatibilityMatrixView: View {
    public let matrix: [CardMatrixItem]

    public var body: some View {
        List {
            ForEach(matrix) { item in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(item.issuer.displayName)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(item.issuer.primaryColor)

                        Spacer()

                        StatusPillView(status: item.balanceSupport, labelPrefix: "Saldo")
                    }

                    Text("Versi: \(item.targetVersion)")
                        .font(.system(size: 13, weight: .semibold))

                    Text(item.notes)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("Matriks Kompatibilitas")
    }
}
