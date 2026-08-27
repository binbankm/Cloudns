import SwiftUI

/// Cloudns 全局圆角规范 Token (Apple HIG 连续曲率 Continuous Corner Radius)
/// 命名严格遵循从小到大语义顺序：xs → sm → md → mdLg → lg → xl → xxl
public enum CloudnsRadius {
    /// 4pt - 微圆角（微标签、微徽标、进度指示器）
    public static let xs: CGFloat = 4
    /// 6pt - 紧凑圆角（列表小图标背景、轻量 Badge）
    public static let sm: CGFloat = 6
    /// 8pt - 小型圆角（标准按钮、Segment 选择器）
    public static let md: CGFloat = 8
    /// 10pt - 次中型圆角（输入框、代码块、辅助卡片）
    public static let mdLg: CGFloat = 10
    /// 12pt - 中型圆角（标准卡片、弹窗内部区块）
    public static let lg: CGFloat = 12
    /// 16pt - 大型圆角（外层卡片、主内容卡片、Sheet 容器）
    public static let xl: CGFloat = 16
    /// 20pt - 超大圆角（模态大卡片、Hero 模块）
    public static let xxl: CGFloat = 20
    /// 999pt - 胶囊药丸圆角（Capsule 状态标签、Chip 容器）
    public static let full: CGFloat = 999

    // MARK: - Backward Compatibility Aliases

    /// @deprecated 请改用 CloudnsRadius.sm (6pt)
    @available(*, deprecated, renamed: "sm")
    public static let xxs: CGFloat = sm

    /// @deprecated 请改用 CloudnsRadius.mdLg (10pt)
    @available(*, deprecated, renamed: "mdLg")
    public static let smMd: CGFloat = mdLg
}

// MARK: - View Extension

public extension View {
    /// 便捷应用符合 Apple HIG 连续平滑曲率 (Continuous Style) 的 Cloudns 圆角裁剪
    func cloudnsCornerRadius(_ radius: CGFloat = CloudnsRadius.lg) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

