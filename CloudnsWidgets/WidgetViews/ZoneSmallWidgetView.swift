import SwiftUI
import WidgetKit

// MARK: - ZoneSmallWidgetView

public struct ZoneSmallWidgetView: View {
    let snapshot: ZoneWidgetSnapshot
    
    public init(snapshot: ZoneWidgetSnapshot) {
        self.snapshot = snapshot
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Domain Icon + Status Indicator
            HStack(spacing: 6) {
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
                    .frame(width: 8, height: 8)
            }
            
            Spacer(minLength: 0)
            
            // Middle: 24h Requests Main Metric
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.formattedRequests)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text("24h Requests")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 0)
            
            // Footer: Cache Ratio & SSL Badge
            HStack(spacing: 6) {
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                    Text(snapshot.formattedCachedRatio)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.12))
                .clipShape(Capsule())
                
                Spacer(minLength: 0)
                
                if snapshot.isSSLEnabled {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                }
                
                if snapshot.isProxied {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(14)
        .widgetURL(URL(string: "cloudns://zone/\(snapshot.id)"))
    }
}
