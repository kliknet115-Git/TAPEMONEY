import Foundation
import SwiftData

/// Repositori penyimpanan lokal SwiftData untuk profil kartu, hasil scan, dan transaksi
/// Memenuhi FR-008, FR-009, FR-010, FR-012
@MainActor
public final class CardDataRepository: ObservableObject {
    public let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Save Scan Result
    /// Menyimpan hasil scan baru, memperbarui saldo kartu terkait atau membuat profil baru jika kartu belum terdaftar
    @discardableResult
    public func saveScanResult(_ result: CardReadResult, customAlias: String? = nil) throws -> ScanRecord {
        let identifier = result.maskedIdentifier

        // Cari apakah profil kartu sudah ada
        let descriptor = FetchDescriptor<CardProfile>(
            predicate: #Predicate { $0.maskedCardIdentifier == identifier }
        )
        let existingProfiles = try? modelContext.fetch(descriptor)
        let profile: CardProfile

        if let found = existingProfiles?.first {
            profile = found
            profile.lastScannedAt = Date()
            if let newBalance = result.balance {
                profile.latestBalance = newBalance
            }
            if let customAlias = customAlias, !customAlias.isEmpty {
                profile.alias = customAlias
            }
        } else {
            let defaultAlias = customAlias?.isEmpty == false ? customAlias! : "\(result.issuer.brandName) Baru"
            profile = CardProfile(
                alias: defaultAlias,
                issuer: result.issuer,
                cardType: result.cardType,
                cardGeneration: result.cardGeneration,
                maskedCardIdentifier: result.maskedIdentifier,
                createdAt: Date(),
                lastScannedAt: Date(),
                latestBalance: result.balance
            )
            modelContext.insert(profile)
        }

        // Buat ScanRecord baru
        let scanRecord = ScanRecord(
            cardProfile: profile,
            scannedAt: Date(),
            balance: result.balance,
            balanceStatus: result.balanceStatus,
            historyStatus: result.historyStatus,
            adapterVersion: result.adapterVersion,
            appVersion: "2.0.0",
            deviceModel: "iPhone"
        )
        modelContext.insert(scanRecord)

        // Buat TransactionRecords jika ada transaksi yang dibaca dari kartu
        for (index, tx) in result.transactions.enumerated() {
            let txRecord = TransactionRecord(
                scanRecord: scanRecord,
                transactionDate: tx.date,
                amount: tx.amount,
                transactionType: tx.type,
                merchantLocation: tx.merchantOrTerminal,
                recordSequence: tx.sequence ?? (index + 1),
                source: "on_card"
            )
            modelContext.insert(txRecord)
            scanRecord.transactions.append(txRecord)
        }

        profile.scans.append(scanRecord)
        try modelContext.save()
        return scanRecord
    }

    // MARK: - Update Card
    public func updateCardAlias(profile: CardProfile, newAlias: String) throws {
        profile.alias = newAlias
        try modelContext.save()
    }

    // MARK: - Delete Operations
    public func deleteCard(profile: CardProfile) throws {
        modelContext.delete(profile)
        try modelContext.save()
    }

    public func deleteScanRecord(_ scan: ScanRecord) throws {
        modelContext.delete(scan)
        try modelContext.save()
    }

    /// Menghapus seluruh data aplikasi (FR-012)
    public func resetAllData() throws {
        let profiles = try modelContext.fetch(FetchDescriptor<CardProfile>())
        for p in profiles {
            modelContext.delete(p)
        }
        let scans = try modelContext.fetch(FetchDescriptor<ScanRecord>())
        for s in scans {
            modelContext.delete(s)
        }
        let txs = try modelContext.fetch(FetchDescriptor<TransactionRecord>())
        for t in txs {
            modelContext.delete(t)
        }
        try modelContext.save()
    }

    // MARK: - Seed Mock Data for Previews
    public func seedPreviewDataIfEmpty() {
        let count = (try? modelContext.fetchCount(FetchDescriptor<CardProfile>())) ?? 0
        guard count == 0 else { return }

        let sampleProfiles = MockNFCData.sampleCardProfiles()
        for p in sampleProfiles {
            modelContext.insert(p)
            let scan = ScanRecord(
                cardProfile: p,
                scannedAt: p.lastScannedAt ?? Date(),
                balance: p.latestBalance,
                balanceStatus: .success,
                historyStatus: .success,
                adapterVersion: "2.0",
                appVersion: "2.0.0"
            )
            modelContext.insert(scan)
            p.scans.append(scan)
        }
        try? modelContext.save()
    }
}
