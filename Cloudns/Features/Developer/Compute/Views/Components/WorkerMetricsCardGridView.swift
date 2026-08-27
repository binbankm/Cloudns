import SwiftUI

// MARK: - WorkerMetricsCardGridView

struct WorkerMetricsCardGridView: View {
    // MARK: - Properties
    let totalRequests: Int
    let totalSubrequests: Int
    let totalErrors: Int
    let errorRatePercentage: Double
    let avgCpuP50: Double
    let maxCpuP99: Double
    
    // MARK: - Body
    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                metricCard(
                    title: "Invocations",
                    value: formatNumber(totalRequests),
                    icon: "bolt.horizontal.fill",
                    color: .purple,
                    badge: "\(formatNumber(totalSubrequests)) Subrequests"
                )
                
                metricCard(
                    title: "Error Rate",
                    value: String(format: "%.1f%%", errorRatePercentage),
                    icon: "exclamationmark.triangle.fill",
                    color: errorRatePercentage > 0 ? .red : .green,
                    badge: "\(formatNumber(totalErrors)) Errors"
                )
            }
            
            GridRow {
                metricCard(
                    title: "Median CPU",
                    value: String(format: "%.2f ms", avgCpuP50),
                    icon: "timer",
                    color: .cyan,
                    badge: "50th Percentile"
                )
                
                metricCard(
                    title: "Max CPU (P99)",
                    value: String(format: "%.2f ms", maxCpuP99),
                    icon: "speedometer",
                    color: .orange,
                    badge: "99th Percentile"
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 22, height: 22)
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
            
            Spacer(minLength: 2)
            
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Spacer(minLength: 2)
            
            Text(badge)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 102, maxHeight: 102, alignment: .topLeading)
        .background(CloudnsColor.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg))
    }
    
    // MARK: - Helpers
    private func formatNumber(_ n: Int) -> String {
        if n >= 1_000_000 {
            return String(format: "%.1fM", Double(n) / 1_000_000)
        } else if n >= 1_000 {
            return String(format: "%.1fk", Double(n) / 1_000)
        }
        return "\(n)"
    }
}
