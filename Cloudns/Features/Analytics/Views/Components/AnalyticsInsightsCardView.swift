import SwiftUI

// MARK: - AnalyticsInsightsCardView

struct AnalyticsInsightsCardView: View {
    // MARK: - Properties
    let totalCachedBandwidthBytes: Int
    let cachedRatio: Double
    let formatBytes: (Int) -> String
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Edge Caching Savings", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.blue)
            
            HStack {
                Text("Origin Bandwidth Saved")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatBytes(totalCachedBandwidthBytes))
                    .font(.caption.weight(.semibold).monospacedDigit())
            }
            
            Divider()
            
            HStack {
                Text("Edge Cache Ratio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(verbatim: String(format: "%.1f%%", cachedRatio * 100))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(cachedRatio > 0.5 ? .green : .orange)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
