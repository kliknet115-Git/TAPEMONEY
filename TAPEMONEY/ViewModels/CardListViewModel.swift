import Foundation
import SwiftUI

/// ViewModel untuk Daftar Kartu dan Manajemen Profil (Bab 10.4 PRD)
@MainActor
public final class CardListViewModel: ObservableObject {
    @Published public var searchText: String = ""
    @Published public var editingProfile: CardProfile? = nil
    @Published public var editAliasText: String = ""

    public init() {}

    public func startEditing(_ profile: CardProfile) {
        self.editingProfile = profile
        self.editAliasText = profile.alias
    }

    public func saveEditing(with repository: CardDataRepository) {
        guard let profile = editingProfile, !editAliasText.trimmingCharacters(in: .whitespaces).isEmpty else {
            editingProfile = nil
            return
        }
        do {
            try repository.updateCardAlias(profile: profile, newAlias: editAliasText)
        } catch {
            print("Gagal mengubah alias kartu: \(error)")
        }
        editingProfile = nil
    }

    public func deleteCard(_ profile: CardProfile, with repository: CardDataRepository) {
        do {
            try repository.deleteCard(profile: profile)
        } catch {
            print("Gagal menghapus kartu: \(error)")
        }
    }
}
