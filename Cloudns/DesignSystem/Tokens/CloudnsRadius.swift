import SwiftUI

/// Cloudns 全局圆角规范 Token
public enum CloudnsRadius {
    /// 4pt - 微圆角（标签、微徽标）
    public static let xs: CGFloat = 4
    /// 8pt - 小型圆角（按钮、输入框、小图标底色）
    public static let sm: CGFloat = 8
    /// 12pt - 中型圆角（标准卡片、弹窗内部区块）
    public static let md: CGFloat = 12
    /// 16pt - 大型圆角（外层卡片、主内容卡片、Sheet 容器）
    public static let lg: CGFloat = 16
    /// 20pt - 超大圆角（模态大卡片、Hero 模块）
    public static let xl: CGFloat = 20
    /// 999pt - 胶囊药丸圆角（Capsule 状态标签、Chip）
    public static let full: CGFloat = 999
}
