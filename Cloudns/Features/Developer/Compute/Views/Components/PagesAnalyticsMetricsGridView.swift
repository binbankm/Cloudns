import SwiftUI

// MARK: - PagesAnalyticsMetricsGridView

struct PagesAnalyticsMetricsGridView: View {
    // MARK: - Properties
    let totalRequests: Int
    let totalSubrequests: Int
    let totalErrors: Int
    let errorRatePercentage: Double
    let deploymentSuccessRate: Double
    let totalDeploymentsCount: Int
    let customDomainsCount: Int
    
    // MARK: - Body
    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                metricCard(
                    title: "Functions Invocations",
                    value: formatNumber(totalRequests),
                    icon: "bolt.horizontal.fill",
                    color: .blue,
                    badge: "\(formatNumber(totalSubrequests)) Subrequests"
                )
                
                metricCard(
                    title: "Functions Errors",
                    value: formatNumber(totalErrors),
                    icon: "exclamationmark.triangle.fill",
                    color: totalErrors > 0 ? .red : .green,
                    badge: "\(String(format: "%.1f%%", errorRatePercentage)) Error Rate"
                )
            }
            
            GridRow {
                metricCard(
                    title: "Deploy Success Rate",
                    value: String(format: "%.0f%%", deploymentSuccessRate),
                    icon: "checkmark.seal.fill",
                    color: .green,
                    badge: "\(totalDeploymentsCount) Total Deploys"
                )
                
                metricCard(
                    title: "Active Domains",
                    value: "\(customDomainsCount)",
                    icon: "globe",
                    color: .purple,
                    badge: "Custom Domains"
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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
