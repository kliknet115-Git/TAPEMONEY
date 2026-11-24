import SwiftUI

/// Pill badge indikator status kompatibilitas (FR-011 PRD)
public struct StatusPillView: View {
    public let status: CompatibilityStatus
    public let labelPrefix: String?

    public init(status: CompatibilityStatus, labelPrefix: String? = nil) {
        self.status = status
        self.labelPrefix = labelPrefix
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status.iconName)
                .font(.system(size: 11, weight: .bold))

            if let prefix = labelPrefix {
                Text("\(prefix): \(status.localizedTitle)")
                    .font(.system(size: 12, weight: .semibold))
            } else {
                Text(status.localizedTitle)
                    .font(.system(size: 12, weight: .semibold))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.badgeColor.opacity(0.14))
        .foregroundColor(status.badgeColor)
        .cornerRadius(12)
    }
}
