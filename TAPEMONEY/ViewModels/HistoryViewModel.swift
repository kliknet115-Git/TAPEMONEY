import Foundation
import SwiftUI

/// ViewModel untuk Riwayat Scan dan Analisis Pembacaan (Bab 10.5 PRD)
@MainActor
public final class HistoryViewModel: ObservableObject {
    public let repository: CardDataRepository
    @Published public var selectedIssuerFilter: CardIssuer? = nil
    @Published public var shareURL: URL? = nil
    @Published public var showShareSheet: Bool = false

    public init(repository: CardDataRepository) {
        self.repository = repository
    }

    public func exportCSV(from scans: [ScanRecord]) {
        if let url = CSVExportService.generateCSV(from: scans) {
            self.shareURL = url
            self.showShareSheet = true
        }
    }

    public func deleteScan(_ scan: ScanRecord) {
        do {
            try repository.deleteScanRecord(scan)
        } catch {
            print("Gagal menghapus riwayat scan: \(error)")
        }
    }
}
