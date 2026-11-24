import Foundation
import SwiftUI
import Combine

/// ViewModel untuk Layar Beranda (Bab 10.1 PRD)
@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public var showScanSheet: Bool = false
    @Published public var showSimulatedScanSheet: Bool = false
    @Published public var selectedSimulationIssuer: CardIssuer = .bca

    public init() {}
}
