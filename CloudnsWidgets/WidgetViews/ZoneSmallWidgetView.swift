import SwiftUI
import WidgetKit

// MARK: - ZoneSmallWidgetView

public struct ZoneSmallWidgetView: View {
    let snapshot: ZoneWidgetSnapshot
    
    public init(snapshot: ZoneWidgetSnapshot) {
        self.snapshot = snapshot
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: Domain Icon + Name + Status Indicator
            HStack(spacing: 5) {
                Image(systemName: "globe")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                
                Text(snapshot.name)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
                
                Circle()
                    .fill(snapshot.status == "active" ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)
            }
            
            Spacer(minLength: 0)
            
            // 2x2 Metric Grid (All 4 Core Metrics)
            VStack(spacing: 6) {
                // Row 1: Requests & Bandwidth
                HStack(spacing: 6) {
                    metricCard(
                        title: "Requests",
                        value: snapshot.formattedRequests,
                        icon: "chart.line.uptrend.xyaxis",
                        color: .blue
                    )
                    
                    metricCard(
                        title: "Bandwidth",
                        value: snapshot.formattedBytes,
                        icon: "arrow.up.arrow.down",
                        color: .indigo
                    )
                }
                
                // Row 2: Cached & Threats
                HStack(spacing: 6) {
                    metricCard(
                        title: "Cached",
                        value: snapshot.formattedCachedRatio,
                        icon: "bolt.fill",
                        color: .orange
                    )
                    
                    metricCard(
                        title: "Threats",
                        value: "\(snapshot.threats24h)",
                        icon: "shield.checkered",
                        color: .green
                    )
                }
            }
        }
        .padding(12)
        .widgetURL(URL(string: "cloudns://zone/\(snapshot.id)"))
    }
    
    @ViewBuilder
    private func metricCard(title: LocalizedStringKey, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
        .padding(.vertical, 4.5)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
