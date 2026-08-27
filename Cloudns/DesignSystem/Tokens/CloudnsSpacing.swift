import SwiftUI

/// Cloudns 全局间距常量 Token (8pt 网格系统与 Apple HIG 间距阶梯)
public enum CloudnsSpacing {
    /// 2pt - 极细间隙 (微指示器、紧凑内边距)
    public static let xxs: CGFloat = 2
    /// 4pt - 微小间距 (文字与图标间距、Badge 内部间距)
    public static let xs: CGFloat = 4
    /// 8pt - 紧凑间距 (列表行内子元素间距、紧凑卡片间距)
    public static let sm: CGFloat = 8
    /// 10pt - 适中小间距 (输入框垂直间距、标签横向内边距)
    public static let smMd: CGFloat = 10
    /// 12pt - 常规小间距 (子视图垂直间隔、次级卡片内边距)
    public static let mdSmall: CGFloat = 12
    /// 14pt - 常用适中内边距 (卡片紧凑内边距)
    public static let mdMedium: CGFloat = 14
    /// 16pt - 标准间距 (页面左右边距、标准卡片内边距)
    public static let md: CGFloat = 16
    /// 20pt - 适度大间距 (卡片间距、大 Section 间距)
    public static let mdLarge: CGFloat = 20
    /// 24pt - 大间距 (模态内边距、区块间距)
    public static let lg: CGFloat = 24
    /// 32pt - 特大间距 (Hero 顶部间距、空状态间距)
    public static let xl: CGFloat = 32
    /// 48pt - 页面分节超大间距 (登录页、Onboarding 模块间距)
    public static let xxl: CGFloat = 48
}

// MARK: - EdgeInsets Helpers

public extension EdgeInsets {
    /// 标准卡片边距 (top: 14, leading: 16, bottom: 14, trailing: 16)
    static var cloudnsCard: EdgeInsets {
        EdgeInsets(top: CloudnsSpacing.mdMedium, leading: CloudnsSpacing.md, bottom: CloudnsSpacing.mdMedium, trailing: CloudnsSpacing.md)
    }
    
    /// 紧凑卡片边距 (top: 10, leading: 12, bottom: 10, trailing: 12)
    static var cloudnsCardCompact: EdgeInsets {
        EdgeInsets(top: CloudnsSpacing.smMd, leading: CloudnsSpacing.mdSmall, bottom: CloudnsSpacing.smMd, trailing: CloudnsSpacing.mdSmall)
    }
    
    /// 标准列表行内边距 (top: 8, leading: 16, bottom: 8, trailing: 16)
    static var cloudnsListRow: EdgeInsets {
        EdgeInsets(top: CloudnsSpacing.sm, leading: CloudnsSpacing.md, bottom: CloudnsSpacing.sm, trailing: CloudnsSpacing.md)
    }
}
