import SwiftUI
import WidgetKit

// MARK: - StatusMediumWidgetView

public struct StatusMediumWidgetView: View {
    let snapshot: CFStatusWidgetSnapshot
    
    public init(snapshot: CFStatusWidgetSnapshot) {
        self.snapshot = snapshot
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "cloud.fill")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.orange)
                
                Text("Cloudflare Global Status")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(LocalizedStringKey(snapshot.isOperational ? "Operational" : snapshot.indicator.capitalized))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.12))
                .clipShape(Capsule())
            }
            
            Divider()
            
            // Status Info Body
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: snapshot.isOperational ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.description)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if let incident = snapshot.latestIncidentTitle, !incident.isEmpty {
                        Text(incident)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text("All 330+ Global Data Centers Operational")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
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
