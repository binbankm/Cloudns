import SwiftUI

// MARK: - ZoneRowView

struct ZoneRowView: View {
    let zone: Zone
    
    init(zone: Zone) {
        self.zone = zone
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
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Leading Initial Avatar with Deterministic Color Hashing
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.14))
                    .frame(width: 38, height: 38)
                Text(initialChar)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(avatarColor)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(zone.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                // Warning Badges (Only show when active)
                if zone.paused || (zone.developmentMode ?? 0) > 0 {
                    HStack(spacing: 6) {
                        if zone.paused {
                            Text("Paused")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.15))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        
                        if (zone.developmentMode ?? 0) > 0 {
                            Text("Dev Mode")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundStyle(.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }
            
            Spacer()
            
            // Status Badge
            CloudnsBadge(
                zone.status.lowercased() == "active" ? .active("Active") : .warning(zone.status.capitalized),
                isCompact: true
            )
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(zone.name), status \(zone.status)")
    }
}
