import SwiftUI

/// Navigasi Tab Utama Aplikasi TAPEMONEY
public struct MainTabView: View {
    public var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Beranda", systemImage: "wave.3.forward.circle.fill")
                }

            CardListView()
                .tabItem {
                    Label("Kartu Saya", systemImage: "creditcard.fill")
                }

            HistoryView()
                .tabItem {
                    Label("Riwayat", systemImage: "clock.arrow.circlepath")
                }

            SettingsView()
                .tabItem {
                    Label("Pengaturan", systemImage: "gearshape.fill")
                }
        }
    }
}
