import SwiftUI
import SwiftData

/// Titik Masuk Utama Aplikasi iOS TAPEMONEY
@main
struct TAPEMONEYApp: App {
    let container: ModelContainer
    @StateObject private var nfcCoordinator = NFCScanCoordinator()

    init() {
        do {
            let schema = Schema([
                CardProfile.self,
                ScanRecord.self,
                TransactionRecord.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Gagal menginisialisasi SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(container)
                .environmentObject(nfcCoordinator)
                .environmentObject(CardDataRepository(modelContext: container.mainContext))
        }
    }
}
