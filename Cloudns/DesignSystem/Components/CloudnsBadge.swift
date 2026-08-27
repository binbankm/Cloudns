import SwiftUI

/// 订阅与套餐层级枚举
public enum PlanTier: String, Codable, Sendable {
    case free = "free"
    case pro = "pro"
    case business = "business"
    case enterprise = "enterprise"
    case paid = "paid"
    case addOn = "addon"
    
    public var title: String {
        switch self {
        case .free: return "FREE"
        case .pro: return "PRO"
        case .business: return "BUSINESS"
        case .enterprise: return "ENTERPRISE"
        case .paid: return "PAID"
        case .addOn: return "ADD-ON"
        }
    }
}

/// 语义徽章与胶囊标签类型
public enum CloudnsBadgeType {
    /// Cloudflare 经典橙色 CDN 代理加速 (带小云朵 ☁️)
    case proxied(String = "Proxied")
    /// 仅 DNS 回源解析 (带灰色小云朵 ☁️)
    case dnsOnly(String = "DNS Only")
    /// 正常运行 / 生效中状态 (绿色呼吸灯)
    case active(String = "Active")
    /// 警告 / 降级 / 待确认状态 (橙色呼吸灯)
    case warning(String = "Pending")
    /// 危险 / 失败 / 拦截状态 (红色呼吸灯)
    case danger(String = "Error")
    /// 暂停 / 禁用状态 (灰色)
    case paused(String = "Paused")
    /// 自定义文本与颜色药丸
    case custom(color: Color, text: String, icon: String? = nil)
    /// 会员/计划级别标签 (Free/Pro/Business/Enterprise)
    case tier(PlanTier)
    
    public static var proxied: CloudnsBadgeType { .proxied() }
    public static var dnsOnly: CloudnsBadgeType { .dnsOnly() }
    public static var active: CloudnsBadgeType { .active() }
    public static var warning: CloudnsBadgeType { .warning() }
    public static var danger: CloudnsBadgeType { .danger() }
    public static var error: CloudnsBadgeType { .danger() }
    public static func error(_ text: String) -> CloudnsBadgeType { .danger(text) }
    public static var paused: CloudnsBadgeType { .paused() }
    public static var free: CloudnsBadgeType { .tier(.free) }
    public static var pro: CloudnsBadgeType { .tier(.pro) }
    public static var business: CloudnsBadgeType { .tier(.business) }
    public static var enterprise: CloudnsBadgeType { .tier(.enterprise) }
    public static var paid: CloudnsBadgeType { .tier(.paid) }
    public static var addOn: CloudnsBadgeType { .tier(.addOn) }
    
    public static func plan(_ tier: PlanTier) -> CloudnsBadgeType {
        .tier(tier)
    }
    
    public static func custom(_ text: String, color: Color, icon: String? = nil) -> CloudnsBadgeType {
        .custom(color: color, text: text, icon: icon)
    }
}

// MARK: - Cloudns Badge View

public struct CloudnsBadge: View {
    let type: CloudnsBadgeType
    let isCompact: Bool
    @Environment(\.redactionReasons) private var redactionReasons
    
    private var isRedacted: Bool {
        redactionReasons.contains(.placeholder)
    }
    
    public init(_ type: CloudnsBadgeType, isCompact: Bool = false) {
        self.type = type
        self.isCompact = isCompact
    }
    
    public var body: some View {
        HStack(spacing: isCompact ? 3 : 3.5) {
            badgeIcon
            
            Text(LocalizedStringKey(badgeText))
                .font(isCompact ? .caption2.weight(.medium) : .caption.weight(.medium))
                .foregroundStyle(isRedacted ? Color(.tertiarySystemFill) : badgeColor)
        }
        .padding(.horizontal, isCompact ? 5 : 6.5)
        .padding(.vertical, isCompact ? 1.5 : 2.5)
        .background(isRedacted ? Color(.tertiarySystemFill) : badgeColor.opacity(0.10))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isRedacted ? Color.clear : badgeColor.opacity(0.18), lineWidth: 0.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(badgeText)
    }
    
    @ViewBuilder
    private var badgeIcon: some View {
        if isRedacted {
            EmptyView()
        } else {
            switch type {
            case .proxied:
                Image(systemName: "cloud.fill")
                    .font(isCompact ? .caption2 : .caption)
                    .foregroundStyle(badgeColor)
            case .dnsOnly:
                Image(systemName: "cloud")
                    .font(isCompact ? .caption2 : .caption)
                    .foregroundStyle(badgeColor)
            case .active:
                Circle()
                    .fill(CloudnsColor.success)
                    .frame(width: isCompact ? 4 : 4.5, height: isCompact ? 4 : 4.5)
                    .shadow(color: CloudnsColor.success.opacity(0.5), radius: 2, x: 0, y: 0)
            case .warning:
                Circle()
                    .fill(CloudnsColor.warning)
                    .frame(width: isCompact ? 4 : 4.5, height: isCompact ? 4 : 4.5)
            case .danger:
                Circle()
                    .fill(CloudnsColor.danger)
                    .frame(width: isCompact ? 4 : 4.5, height: isCompact ? 4 : 4.5)
            case .paused:
                Circle()
                    .fill(CloudnsColor.dnsOnly)
                    .frame(width: isCompact ? 4 : 4.5, height: isCompact ? 4 : 4.5)
            case .custom(_, _, let icon):
                if let icon = icon {
                    Image(systemName: icon)
                        .font(isCompact ? .caption2 : .caption)
                        .foregroundStyle(badgeColor)
                }
            case .tier(let tier):
                switch tier {
                case .free:
                    Image(systemName: "checkmark.circle.fill")
                        .font(isCompact ? .caption2 : .caption)
                        .foregroundStyle(badgeColor)
                case .pro:
                    Image(systemName: "sparkles")
                        .font(isCompact ? .caption2 : .caption)
                        .foregroundStyle(badgeColor)
                case .business:
                    Image(systemName: "briefcase.fill")
                        .font(isCompact ? .caption2 : .caption)
                        .foregroundStyle(badgeColor)
                case .enterprise:
                    Image(systemName: "building.2.fill")
                        .font(isCompact ? .caption2 : .caption)
                        .foregroundStyle(badgeColor)
                case .paid:
                    Image(systemName: "bolt.fill")
                        .font(isCompact ? .caption2 : .caption)
                        .foregroundStyle(badgeColor)
                case .addOn:
                    Image(systemName: "plus.circle.fill")
                        .font(isCompact ? .caption2 : .caption)
                        .foregroundStyle(badgeColor)
                }
            }
        }
    }
    
    private var badgeColor: Color {
        if isRedacted {
            return Color(.tertiarySystemFill)
        }
        switch type {
        case .proxied:
            return CloudnsColor.brandAccent
        case .dnsOnly:
            return CloudnsColor.dnsOnly
        case .active:
            return CloudnsColor.success
        case .warning:
            return CloudnsColor.warning
        case .danger:
            return CloudnsColor.danger
        case .paused:
            return CloudnsColor.dnsOnly
        case .custom(let color, _, _):
            return color
        case .tier(let tier):
            switch tier {
            case .free:
                return CloudnsColor.security
            case .pro:
                return CloudnsColor.brand
            case .business:
                return CloudnsColor.brandAccent
            case .enterprise:
                return CloudnsColor.ai
            case .paid:
                return CloudnsColor.brandDark
            case .addOn:
                return CloudnsColor.database
            }
        }
    }
    
    private var badgeText: String {
        switch type {
        case .proxied(let text):
            return text
        case .dnsOnly(let text):
            return text
        case .active(let text):
            return text
        case .warning(let text):
            return text
        case .danger(let text):
            return text
        case .paused(let text):
            return text
        case .custom(_, let text, _):
            return text
        case .tier(let tier):
            return tier.title
        }
    }
}
