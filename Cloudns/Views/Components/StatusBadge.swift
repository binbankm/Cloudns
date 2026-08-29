import SwiftUI

// MARK: - Status Badge Type

public enum StatusBadgeType {
    /// Cloudflare 经典橙色 CDN 代理加速 (带小云朵 ☁️)
    case proxied(String = "Proxied")
    /// 仅 DNS 回源解析 (带灰色小云朵 ☁️)
    case dnsOnly(String = "DNS Only")
    /// 运行健康 (带绿色呼吸灯 🟢)
    case active(String = "Active")
    /// 服务降级 / 告警 (带黄色警示灯 🟡)
    case warning(String = "Warning")
    /// 拦截 / 错误 (带红色指示灯 🔴)
    case error(String = "Error")
    /// 官方套餐计划徽标 (FREE / PRO / BUSINESS / ENTERPRISE / PAID / ADD-ON)
    case plan(PlanTier)
    /// 自定义徽标
    case custom(color: Color, text: String, icon: String? = nil)
    
    public static var proxied: StatusBadgeType { .proxied() }
    public static var dnsOnly: StatusBadgeType { .dnsOnly() }
    public static var active: StatusBadgeType { .active() }
    public static var warning: StatusBadgeType { .warning() }
    public static var error: StatusBadgeType { .error() }
    public static var free: StatusBadgeType { .plan(.free) }
    public static var pro: StatusBadgeType { .plan(.pro) }
    public static var business: StatusBadgeType { .plan(.business) }
    public static var enterprise: StatusBadgeType { .plan(.enterprise) }
    public static var paid: StatusBadgeType { .plan(.paid) }
    public static var addOn: StatusBadgeType { .plan(.addOn) }
}

public typealias CloudnsBadgeType = StatusBadgeType

// MARK: - Native Status Badge View

public struct StatusBadge: View {
    let type: StatusBadgeType
    let isCompact: Bool
    @Environment(\.redactionReasons) private var redactionReasons
    
    private var isRedacted: Bool {
        redactionReasons.contains(.placeholder)
    }
    
    public init(_ type: StatusBadgeType, isCompact: Bool = false) {
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
                    .fill(Color.green)
                    .frame(width: isCompact ? 4 : 4.5, height: isCompact ? 4 : 4.5)
                    .shadow(color: Color.green.opacity(0.5), radius: 2, x: 0, y: 0)
            case .warning:
                Circle()
                    .fill(Color.orange)
                    .frame(width: isCompact ? 4 : 4.5, height: isCompact ? 4 : 4.5)
            case .error:
                Circle()
                    .fill(Color.red)
                    .frame(width: isCompact ? 4 : 4.5, height: isCompact ? 4 : 4.5)
            case .custom(_, _, let icon):
                if let icon = icon {
                    Image(systemName: icon)
                        .font(isCompact ? .caption2 : .caption)
                        .foregroundStyle(badgeColor)
                }
            case .plan(let tier):
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
            return Color.orange
        case .dnsOnly:
            return Color.secondary
        case .active:
            return Color.green
        case .warning:
            return Color.orange
        case .error:
            return Color.red
        case .custom(let color, _, _):
            return color
        case .plan(let tier):
            switch tier {
            case .free:
                return Color.teal
            case .pro:
                return Color.blue
            case .business:
                return Color.orange
            case .enterprise:
                return Color.purple
            case .paid:
                return Color.indigo
            case .addOn:
                return Color.cyan
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
        case .error(let text):
            return text
        case .custom(_, let text, _):
            return text
        case .plan(let tier):
            return tier.title
        }
    }
}

public typealias CloudnsBadge = StatusBadge
