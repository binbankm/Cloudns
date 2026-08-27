import Foundation

/// Cloudns 全局尺寸规范 Token (Apple HIG 物理像素与可访问性触控区标准)
public enum CloudnsSize {
    // MARK: - HIG Touch Target
    
    /// Apple HIG 推荐的最小触控区域尺寸 (44pt x 44pt)
    public static let minTouchTarget: CGFloat = 44
    
    // MARK: - Icon Sizes
    
    /// 微型辅助图标 (12pt，用于 Badge 或小指示器)
    public static let iconMini: CGFloat = 12
    /// 小型状态图标 (14pt ~ 16pt，用于列表项辅助图标)
    public static let iconSmall: CGFloat = 16
    /// 标准正文图标 (20pt，用于表单前置图标、按钮前置图标)
    public static let iconMedium: CGFloat = 20
    /// 大号重点图标 (24pt，用于 Section 标题前缀图标)
    public static let iconLarge: CGFloat = 24
    /// Hero 大尺寸展示图标 (36pt，用于列表行左侧大图标)
    public static let iconHero: CGFloat = 36
    /// 超大 Hero 图标 (64pt，用于 EmptyState 圆形图标容器、功能引导页)
    public static let iconXL: CGFloat = 64
    
    // MARK: - Avatar & Round Badges
    
    /// 紧凑头像 / 指标圆圈 (28pt)
    public static let avatarSmall: CGFloat = 28
    /// 标准列表头像 (38pt)
    public static let avatarMedium: CGFloat = 38
    /// 头部 Hero 头像 (48pt)
    public static let avatarLarge: CGFloat = 48
    /// 大型 Hero 头像 / App 图标预览 (64pt)
    public static let avatarXL: CGFloat = 64
    
    // MARK: - Input & Controls Heights
    
    /// 紧凑控件高度 (32pt)
    public static let controlHeightSmall: CGFloat = 32
    /// 标准输入框 / 按钮高度 (40pt)
    public static let controlHeightRegular: CGFloat = 40
    /// 标准输入框 / 按钮高度别名 (40pt)
    public static let controlHeight: CGFloat = 40
    /// 大型主操作按钮 / 登录输入框高度 (48pt)
    public static let controlHeightLarge: CGFloat = 48
}
