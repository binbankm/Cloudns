import SwiftUI
import WidgetKit

// MARK: - StatusSmallWidgetView

public struct StatusSmallWidgetView: View {
    let snapshot: CFStatusWidgetSnapshot
    
    public init(snapshot: CFStatusWidgetSnapshot) {
        self.snapshot = snapshot
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "cloud.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                
                Text("Cloudflare")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                
                Spacer(minLength: 0)
                
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }
            
            Spacer(minLength: 0)
            
            // Icon + Status
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: snapshot.isOperational ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(statusColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.isOperational ? "All Systems Operational" : snapshot.description)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                
                if snapshot.activeIncidentsCount > 0 {
                    Text("\(snapshot.activeIncidentsCount) Active Incident(s)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.red)
                } else {
                    Text("Edge Network Normal")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .widgetURL(URL(string: "cloudns://tools/status"))
    }
    
    private var statusColor: Color {
        switch snapshot.indicator.lowercased() {
        case "none": return .green
        case "minor": return .yellow
        case "major": return .orange
        case "critical": return .red
        default: return .green
        }
    }
}
