import SwiftUI

// MARK: - Apple HIG Standard Status Badges

public enum HIGBadgeType: Equatable {
    case proxied(String = "Proxied")
    case dnsOnly(String = "DNS Only")
    case active(String = "Active")
    case free
    case paid
    case pro
    case business
    case enterprise
    case warning(String = "Warning")
    case error(String = "Error")
    case custom(color: Color, text: String, icon: String? = nil)
    
    public static var proxied: HIGBadgeType {
        .proxied("Proxied")
    }
    
    public static var dnsOnly: HIGBadgeType {
        .dnsOnly("DNS Only")
    }
    
    public static var active: HIGBadgeType {
        .active("Active")
    }
}

public struct HIGBadge: View {
    let type: HIGBadgeType
    let isCompact: Bool
    
    public init(_ type: HIGBadgeType, isCompact: Bool = false) {
        self.type = type
        self.isCompact = isCompact
    }
    
    public var body: some View {
        HStack(spacing: isCompact ? 3 : 4) {
            badgeIcon
            Text(badgeText)
                .font(isCompact ? .caption2.weight(.medium) : .caption.weight(.medium))
                .foregroundStyle(badgeColor)
        }
        .padding(.horizontal, isCompact ? 6 : 8)
        .padding(.vertical, isCompact ? 2 : 3)
        .background(badgeColor.opacity(0.12))
        .clipShape(Capsule())
    }
    
    private var badgeText: LocalizedStringKey {
        switch type {
        case .proxied(let text): return LocalizedStringKey(text)
        case .dnsOnly(let text): return LocalizedStringKey(text)
        case .active(let text): return LocalizedStringKey(text)
        case .free: return "FREE"
        case .paid: return "PAID"
        case .pro: return "PRO"
        case .business: return "BIZ"
        case .enterprise: return "ENT"
        case .warning(let msg): return LocalizedStringKey(msg)
        case .error(let msg): return LocalizedStringKey(msg)
        case .custom(_, let text, _): return LocalizedStringKey(text)
        }
    }
    
    private var badgeColor: Color {
        switch type {
        case .proxied: return .orange
        case .dnsOnly: return .secondary
        case .active: return .green
        case .free: return .green
        case .paid: return .purple
        case .pro: return .orange
        case .business: return .teal
        case .enterprise: return .indigo
        case .warning: return .orange
        case .error: return .red
        case .custom(let color, _, _): return color
        }
    }
    
    @ViewBuilder
    private var badgeIcon: some View {
        switch type {
        case .proxied:
            Image(systemName: "cloud.fill")
                .font(isCompact ? .caption2 : .caption)
                .foregroundStyle(badgeColor)
        case .dnsOnly:
            Image(systemName: "cloud")
                .font(isCompact ? .caption2 : .caption)
                .foregroundStyle(badgeColor)
        case .active, .free:
            Circle()
                .fill(badgeColor)
                .frame(width: isCompact ? 5 : 6, height: isCompact ? 5 : 6)
        case .paid, .pro, .business, .enterprise:
            Image(systemName: "sparkles")
                .font(isCompact ? .caption2 : .caption)
                .foregroundStyle(badgeColor)
        case .warning:
            Circle()
                .fill(Color.orange)
                .frame(width: isCompact ? 5 : 6, height: isCompact ? 5 : 6)
        case .error:
            Circle()
                .fill(Color.red)
                .frame(width: isCompact ? 5 : 6, height: isCompact ? 5 : 6)
        case .custom(_, _, let icon):
            if let icon {
                Image(systemName: icon)
                    .font(isCompact ? .caption2 : .caption)
                    .foregroundStyle(badgeColor)
            }
        }
    }
}
