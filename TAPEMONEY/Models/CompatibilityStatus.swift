import Foundation
import SwiftUI

/// Status terpisah untuk pembacaan saldo dan riwayat (sesuai FR-011 PRD)
public enum CompatibilityStatus: String, Codable, CaseIterable {
    case detected = "detected"
    case identified = "identified"
    case balanceSupported = "balanceSupported"
    case historySupported = "historySupported"
    case unsupportedVersion = "unsupportedVersion"
    case notVerified = "notVerified"
    case success = "success"
    case unavailable = "unavailable"
    case failed = "failed"

    public var localizedTitle: String {
        switch self {
        case .detected: return "Terdeteksi"
        case .identified: return "Teridentifikasi"
        case .balanceSupported: return "Saldo Didukung"
        case .historySupported: return "Riwayat Didukung"
        case .unsupportedVersion: return "Versi Belum Didukung"
        case .notVerified: return "Belum Terverifikasi"
        case .success: return "Berhasil"
        case .unavailable: return "Tidak Tersedia"
        case .failed: return "Gagal"
        }
    }

    public var badgeColor: Color {
        switch self {
        case .success, .balanceSupported, .historySupported:
            return Color.green
        case .identified, .detected:
            return Color.blue
        case .notVerified:
            return Color.orange
        case .unsupportedVersion:
            return Color.purple
        case .unavailable, .failed:
            return Color.red
        }
    }

    public var iconName: String {
        switch self {
        case .success, .balanceSupported, .historySupported:
            return "checkmark.circle.fill"
        case .identified, .detected:
            return "tag.fill"
        case .notVerified:
            return "exclamationmark.triangle.fill"
        case .unsupportedVersion:
            return "slash.circle.fill"
        case .unavailable, .failed:
            return "xmark.circle.fill"
        }
    }
}
