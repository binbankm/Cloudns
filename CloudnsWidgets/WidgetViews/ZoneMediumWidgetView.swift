import SwiftUI
import WidgetKit

// MARK: - ZoneMediumWidgetView

public struct ZoneMediumWidgetView: View {
    let snapshot: ZoneWidgetSnapshot
    
    public init(snapshot: ZoneWidgetSnapshot) {
        self.snapshot = snapshot
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            // Left Column: Domain Identity & Core Status
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "network")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.blue)
                    
                    Text(snapshot.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                
                Text(LocalizedStringKey(snapshot.plan))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
                
                HStack(spacing: 6) {
                    HStack(spacing: 4) {
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
                .padding(.vertical, 4)
            
            // Right Column: 3 Metric Tiles
            VStack(alignment: .leading, spacing: 8) {
                // Metric 1: Requests
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(snapshot.formattedRequests)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("24h Requests")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                
                // Metric 2: Cache Ratio
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(snapshot.formattedCachedRatio)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("Cached Traffic")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                // Metric 3: Threats
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(snapshot.threats24h)")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("Threats Mitigated")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "shield.checkered")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .widgetURL(URL(string: "cloudns://zone/\(snapshot.id)"))
    }
}
