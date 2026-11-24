import Foundation
import SwiftUI
import Combine

/// ViewModel untuk Sesi Pemindaian dan Halaman Hasil (Bab 10.2 & 10.3 PRD)
@MainActor
public final class ScanViewModel: ObservableObject {
    public let nfcCoordinator: NFCScanCoordinator
    public let repository: CardDataRepository

    @Published public var cardAliasInput: String = ""
    @Published public var isSaved: Bool = false
    @Published public var saveError: String? = nil

    public init(nfcCoordinator: NFCScanCoordinator, repository: CardDataRepository) {
        self.nfcCoordinator = nfcCoordinator
        self.repository = repository
    }

    public func startScan() {
        isSaved = false
        saveError = nil
        cardAliasInput = ""
        nfcCoordinator.beginScanning()
    }

    public func startSimulation(issuer: CardIssuer) {
        isSaved = false
        saveError = nil
        cardAliasInput = ""
        nfcCoordinator.simulateMockScan(issuer: issuer)
    }

    public func cancelScan() {
        nfcCoordinator.cancelScanning()
    }

    /// Simpan hasil pembacaan kartu ke SwiftData lokal
    public func saveCurrentResult() {
        guard let result = nfcCoordinator.lastResult else { return }
        do {
            try repository.saveScanResult(result, customAlias: cardAliasInput.isEmpty ? nil : cardAliasInput)
            isSaved = true
            saveError = nil
        } catch {
            saveError = "Hasil terbaca, tetapi gagal disimpan: \(error.localizedDescription)"
        }
    }
}
