import SwiftUI

// MARK: - AnalyticsMetricsGridView

struct AnalyticsMetricsGridView: View {
    // MARK: - Properties
    let totalRequests: Int
    let totalCachedRequests: Int
    let totalBandwidthBytes: Int
    let totalCachedBandwidthBytes: Int
    let cachedRatio: Double
    let formatBytes: (Int) -> String
    
    // MARK: - Body
    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                metricCard(
                    title: "Total Requests",
                    value: formatNumber(totalRequests),
                    icon: "globe",
                    color: .blue,
                    badge: "\(formatBytes(totalBandwidthBytes)) Transferred"
                )
                
                metricCard(
                    title: "Cached Requests",
                    value: formatNumber(totalCachedRequests),
                    icon: "bolt.fill",
                    color: .orange,
                    badge: "\(String(format: "%.1f%%", cachedRatio * 100)) Cache Rate"
                )
            }
            
            GridRow {
                metricCard(
                    title: "Cache Hit Ratio",
                    value: String(format: "%.1f%%", cachedRatio * 100),
                    icon: "chart.pie.fill",
                    color: .green,
                    badge: "Edge Served"
                )
                
                metricCard(
                    title: "Data Transferred",
                    value: formatBytes(totalBandwidthBytes),
                    icon: "arrow.up.arrow.down",
                    color: .purple,
                    badge: "\(formatBytes(totalCachedBandwidthBytes)) Saved by Cache"
                )
            }
        }
    }
    
    // MARK: - Private Views
    private func metricCard(
        title: LocalizedStringKey,
        value: String,
        icon: String,
        color: Color,
        badge: LocalizedStringKey
    ) -> some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
            HStack(spacing: CloudnsSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: CloudnsSize.iconMedium, height: CloudnsSize.iconMedium)
                    Image(systemName: icon)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(color)
                }
                .accessibilityHidden(true)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Spacer()
            }
            
            Spacer(minLength: CloudnsSpacing.xxs)
            
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Spacer(minLength: CloudnsSpacing.xxs)
            
            Text(badge)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(CloudnsSpacing.mdSmall)
        .frame(maxWidth: .infinity, minHeight: 102, maxHeight: 102, alignment: .topLeading)
        .background(CloudnsColor.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg))
    }
    
    // MARK: - Helpers
    private func formatNumber(_ num: Int) -> String {
        if num < 1000 { return "\(num)" }
        let k = Double(num) / 1000.0
        if k < 1000 { return String(format: "%.1fK", k) }
        let m = k / 1000.0
        return String(format: "%.2fM", m)
    }
}
