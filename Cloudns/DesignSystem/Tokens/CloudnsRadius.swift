import SwiftUI

/// Cloudns 全局圆角规范 Token
public enum CloudnsRadius {
    /// 4pt - 微圆角（标签、微徽标）
    public static let xs: CGFloat = 4
    /// 6pt - 紧凑圆角（列表小图标背景、轻量 Badge）
    public static let xxs: CGFloat = 6
    /// 8pt - 小型圆角（标准按钮、选择器）
    public static let sm: CGFloat = 8
    /// 10pt - 次中型圆角（紧凑输入框、辅助卡片）
    public static let smMd: CGFloat = 10
    /// 12pt - 中型圆角（标准卡片、弹窗内部区块）
    public static let md: CGFloat = 12
    /// 16pt - 大型圆角（外层卡片、主内容卡片、Sheet 容器）
    public static let lg: CGFloat = 16
    /// 20pt - 超大圆角（模态大卡片、Hero 模块）
    public static let xl: CGFloat = 20
    /// 22pt - 浮动模态圆角（Toast 浮条、浮动控制器）
    public static let xxl: CGFloat = 22
    /// 999pt - 胶囊药丸圆角（Capsule 状态标签、Chip）
    public static let full: CGFloat = 999
}
