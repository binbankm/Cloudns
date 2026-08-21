import SwiftUI
import WidgetKit

// MARK: - ZoneMediumWidgetView

public struct ZoneMediumWidgetView: View {
    let snapshot: ZoneWidgetSnapshot
    
    public init(snapshot: ZoneWidgetSnapshot) {
        self.snapshot = snapshot
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            // Left Column: Domain Identity & Security Badges
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Image(systemName: "globe.americas.fill")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.blue)
                    
                    Text(snapshot.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Text(LocalizedStringKey(snapshot.plan))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
                
                // Status Badges
                HStack(spacing: 5) {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(snapshot.status == "active" ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)
                        Text(LocalizedStringKey(snapshot.status.capitalized))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    if snapshot.isProxied {
                        HStack(spacing: 2) {
                            Image(systemName: "cloud.fill")
                                .font(.system(size: 8))
                            Text("Proxied")
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .padding(.vertical, 2)
            
            // Right Column: 2x2 Metric Grid (4 Metrics)
            VStack(spacing: 6) {
                // Row 1: Requests & Bandwidth
                HStack(spacing: 6) {
                    metricTile(
                        title: "24h Requests",
                        value: snapshot.formattedRequests,
                        icon: "chart.line.uptrend.xyaxis",
                        color: .blue
                    )
                    
                    metricTile(
                        title: "24h Bandwidth",
                        value: snapshot.formattedBytes,
                        icon: "arrow.up.arrow.down",
                        color: .indigo
                    )
                }
                
                // Row 2: Cached & Threats
                HStack(spacing: 6) {
                    metricTile(
                        title: "Cached Traffic",
                        value: snapshot.formattedCachedRatio,
                        icon: "bolt.fill",
                        color: .orange
                    )
                    
                    metricTile(
                        title: "Threats Blocked",
                        value: "\(snapshot.threats24h)",
                        icon: "shield.checkered",
                        color: .green
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .widgetURL(URL(string: "cloudns://zone/\(snapshot.id)"))
    }
    
    @ViewBuilder
    private func metricTile(title: LocalizedStringKey, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
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
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
