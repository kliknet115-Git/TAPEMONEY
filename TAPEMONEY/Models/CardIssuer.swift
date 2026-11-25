import Foundation
import SwiftUI

/// Penerbit kartu uang elektronik yang didukung atau dikenali
public enum CardIssuer: String, Codable, CaseIterable, Identifiable, Sendable {
    case bca = "BCA"
    case mandiri = "Mandiri"
    case bni = "BNI"
    case bri = "BRI"
    case unknown = "Unknown"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .bca: return "BCA Flazz"
        case .mandiri: return "Mandiri e-money"
        case .bni: return "BNI TapCash"
        case .bri: return "BRI BRIZZI"
        case .unknown: return "Kartu Tidak Dikenal"
        }
    }

    public var brandName: String {
        switch self {
        case .bca: return "Flazz"
        case .mandiri: return "e-money"
        case .bni: return "TapCash"
        case .bri: return "BRIZZI"
        case .unknown: return "e-Money"
        }
    }

    public var primaryColor: Color {
        switch self {
        case .bca: return Color(red: 0.05, green: 0.28, blue: 0.63) // BCA Blue
        case .mandiri: return Color(red: 0.02, green: 0.24, blue: 0.54) // Mandiri Dark Blue
        case .bni: return Color(red: 0.96, green: 0.44, blue: 0.16) // BNI Orange
        case .bri: return Color(red: 0.00, green: 0.38, blue: 0.72) // BRI Blue
        case .unknown: return Color(red: 0.35, green: 0.38, blue: 0.45) // Neutral Slate
        }
    }

    public var accentColor: Color {
        switch self {
        case .bca: return Color(red: 0.95, green: 0.75, blue: 0.15)
        case .mandiri: return Color(red: 0.95, green: 0.65, blue: 0.10)
        case .bni: return Color(red: 0.12, green: 0.62, blue: 0.67)
        case .bri: return Color(red: 0.92, green: 0.45, blue: 0.15)
        case .unknown: return Color.gray
        }
    }

    public var gradientColors: [Color] {
        switch self {
        case .bca:
            return [Color(red: 0.05, green: 0.28, blue: 0.63), Color(red: 0.00, green: 0.48, blue: 0.85)]
        case .mandiri:
            return [Color(red: 0.02, green: 0.20, blue: 0.48), Color(red: 0.08, green: 0.35, blue: 0.72)]
        case .bni:
            return [Color(red: 0.92, green: 0.38, blue: 0.12), Color(red: 0.98, green: 0.55, blue: 0.20)]
        case .bri:
            return [Color(red: 0.00, green: 0.32, blue: 0.65), Color(red: 0.00, green: 0.52, blue: 0.88)]
        case .unknown:
            return [Color(red: 0.25, green: 0.28, blue: 0.35), Color(red: 0.40, green: 0.44, blue: 0.52)]
        }
    }

    public var systemIconName: String {
        switch self {
        case .bca, .mandiri, .bni, .bri: return "creditcard.fill"
        case .unknown: return "questionmark.creditcard.fill"
        }
    }
}
