import SwiftUI

// MARK: - Cloudns Shadow Level

public enum CloudnsShadowLevel {
    /// 极软微阴影 (小图标背景、Chip、微列表浮动，radius: 3, y: 1)
    case soft
    /// 标准卡片阴影 (列表卡片、弹层容器，radius: 8, y: 3)
    case card
    /// 突出浮层阴影 (主操作按钮、Toast 浮条、Hero 卡片，radius: 12, y: 5)
    case prominent
    /// 品牌色彩光晕阴影 (带自定义色或主品牌色的高光辉光)
    case brand(color: Color = CloudnsColor.brandAccent, radius: CGFloat = 8, y: CGFloat = 4)
}

// MARK: - Cloudns Shadow Modifier

public struct CloudnsShadowModifier: ViewModifier {
    let level: CloudnsShadowLevel
    @Environment(\.colorScheme) private var colorScheme
    
    public init(level: CloudnsShadowLevel) {
        self.level = level
    }
    
    public func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        
        switch level {
        case .soft:
            content.shadow(
                color: isDark ? Color.black.opacity(0.30) : Color.black.opacity(0.04),
                radius: isDark ? 4 : 3,
                x: 0,
                y: 1
            )
        case .card:
            content.shadow(
                color: isDark ? Color.black.opacity(0.35) : Color.black.opacity(0.06),
                radius: isDark ? 10 : 8,
                x: 0,
                y: isDark ? 4 : 3
            )
        case .prominent:
            content.shadow(
                color: isDark ? Color.black.opacity(0.45) : Color.black.opacity(0.10),
                radius: isDark ? 14 : 12,
                x: 0,
                y: isDark ? 6 : 5
            )
        case .brand(let color, let radius, let y):
            content.shadow(
                color: color.opacity(isDark ? 0.35 : 0.22),
                radius: radius,
                x: 0,
                y: y
            )
        }
    }
}

// MARK: - View Extension

public extension View {
    /// 应用符合 Apple HIG 规范且支持明暗自动适配的 Cloudns 语义阴影
    func cloudnsShadow(_ level: CloudnsShadowLevel = .card) -> some View {
        self.modifier(CloudnsShadowModifier(level: level))
    }
}
