import SwiftUI
import WidgetKit

// MARK: - ZoneAccessoryRectangularView

public struct ZoneAccessoryRectangularView: View {
    let snapshot: ZoneWidgetSnapshot
    
    public init(snapshot: ZoneWidgetSnapshot) {
        self.snapshot = snapshot
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 1.5) {
            // Header: Globe Icon + Domain Name + Status Badge
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.system(size: 11, weight: .bold))
                    .widgetAccentable()
                
                Text(snapshot.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .lineLimit(1)
                
                Spacer(minLength: 0)
                
                if snapshot.isProxied {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 10))
                        .widgetAccentable()
                }
            }
            
            // Primary Metric: Large Bold Number + Requests Label
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(snapshot.formattedRequests)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                
                Text("Requests")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            // Secondary Metric: Cache Traffic Ratio + Threats
            HStack(spacing: 6) {
                HStack(spacing: 2) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8))
                        .widgetAccentable()
                    Text(snapshot.formattedCachedRatio)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                    Text("Cached")
                        .font(.system(size: 9, weight: .medium))
                }
                
                if snapshot.threats24h > 0 {
                    Text("•")
                        .font(.system(size: 8))
                    HStack(spacing: 2) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 8))
                            .widgetAccentable()
                        Text("\(snapshot.threats24h)")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                }
            }
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(URL(string: "cloudns://zone/\(snapshot.id)"))
    }
}
