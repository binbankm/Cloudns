import SwiftUI

// MARK: - Apple HIG Standard Status Badges
// Multi-channel accessibility (Color + Distinct SF Symbol Shape)

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
    case raw(color: Color, text: String, icon: String? = nil)
    
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
        HStack(spacing: isCompact ? HIGTokens.Spacing.xxs + 1 : HIGTokens.Spacing.xs) {
            badgeIcon
            badgeContent
                .font(isCompact ? HIGTypography.caption2.weight(.medium) : HIGTypography.caption.weight(.medium))
                .foregroundStyle(badgeColor)
        }
        .padding(.horizontal, isCompact ? HIGTokens.Spacing.sm - 2 : HIGTokens.Spacing.sm)
        .padding(.vertical, isCompact ? HIGTokens.Spacing.xxs : HIGTokens.Spacing.xs - 1)
        .background(badgeColor.opacity(0.12))
        .clipShape(Capsule())
    }
    
    @ViewBuilder
    private var badgeContent: some View {
        switch type {
        case .proxied(let text): Text(LocalizedStringKey(text))
        case .dnsOnly(let text): Text(LocalizedStringKey(text))
        case .active(let text): Text(LocalizedStringKey(text))
        case .free: Text("FREE")
        case .paid: Text("PAID")
        case .pro: Text("PRO")
        case .business: Text("BIZ")
        case .enterprise: Text("ENT")
        case .warning(let msg): Text(LocalizedStringKey(msg))
        case .error(let msg): Text(LocalizedStringKey(msg))
        case .custom(_, let text, _): Text(LocalizedStringKey(text))
        case .raw(_, let text, _): Text(verbatim: text)
        }
    }
    
    private var badgeColor: Color {
        switch type {
        case .proxied: return .orange
        case .dnsOnly: return .secondary
        case .active: return HIGColors.success
        case .free: return HIGColors.success
        case .paid: return .purple
        case .pro: return .orange
        case .business: return .teal
        case .enterprise: return .indigo
        case .warning: return HIGColors.warning
        case .error: return HIGColors.error
        case .custom(let color, _, _), .raw(let color, _, _): return color
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
                .fill(HIGColors.warning)
                .frame(width: isCompact ? 5 : 6, height: isCompact ? 5 : 6)
        case .error:
            Circle()
                .fill(HIGColors.error)
                .frame(width: isCompact ? 5 : 6, height: isCompact ? 5 : 6)
        case .custom(_, _, let icon), .raw(_, _, let icon):
            if let icon {
                Image(systemName: icon)
                    .font(isCompact ? .caption2 : .caption)
                    .foregroundStyle(badgeColor)
            }
        }
    }
}
