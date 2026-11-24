import SwiftUI

/// Banner status NFC di bagian atas beranda (FR-001 PRD)
public struct NFCStatusBanner: View {
    public let isAvailable: Bool

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isAvailable ? Color.green.opacity(0.18) : Color.orange.opacity(0.18))
                    .frame(width: 36, height: 36)

                Image(systemName: isAvailable ? "wave.3.forward.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isAvailable ? .green : .orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(isAvailable ? "NFC Siap Digunakan" : "NFC Tidak Tersedia")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)

                Text(isAvailable ? "Tempelkan kartu di belakang atas iPhone" : "Perangkat tidak mendukung pembacaan NFC tag")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isAvailable {
                Text("READY")
                    .font(.system(size: 10, weight: .black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}
