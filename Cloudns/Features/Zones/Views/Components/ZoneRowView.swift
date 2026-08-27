import SwiftUI

// MARK: - ZoneRowView

struct ZoneRowView: View {
    let zone: Zone
    let sparkline: ZoneSparklineCache?
    
    init(zone: Zone, sparkline: ZoneSparklineCache? = nil) {
        self.zone = zone
        self.sparkline = sparkline
    }
    
    private var initialChar: String {
        guard let first = zone.name.first else { return "D" }
        return String(first).uppercased()
    }
    
    private var avatarColor: Color {
        let palette: [Color] = [.blue, .indigo, .purple, .teal, .mint, .cyan, .orange, .pink]
        let hash = abs(zone.name.hashValue)
        return palette[hash % palette.count]
    }
    
    @Environment(\.redactionReasons) private var redactionReasons
    
    private var isRedacted: Bool {
        redactionReasons.contains(.placeholder)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Leading Initial Avatar with Deterministic Color Hashing
            ZStack {
                Circle()
                    .fill(isRedacted ? Color(.tertiarySystemFill) : avatarColor.opacity(0.14))
                    .frame(width: 38, height: 38)
                if !isRedacted {
                    Text(initialChar)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(avatarColor)
                }
            }
            .accessibilityHidden(true)
            
            // Domain Info
            VStack(alignment: .leading, spacing: 3) {
                Text(zone.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if zone.paused || (zone.developmentMode ?? 0) > 0 {
                    HStack(spacing: 5) {
                        if zone.paused {
                            Text("Paused")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color.red.opacity(0.15))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        
                        if (zone.developmentMode ?? 0) > 0 {
                            Text("Dev Mode")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color.orange.opacity(0.15))
                                .foregroundStyle(.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }
            
            Spacer(minLength: 8)
            
            // Trailing 24h Traffic Sparkline Chart (Directly rendered with 0ms latency)
            ZoneRowSparklineView(zoneId: zone.id, cached: sparkline)
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(zone.name), status \(zone.status)")
    }
}
