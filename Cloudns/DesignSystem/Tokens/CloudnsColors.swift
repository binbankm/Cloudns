import SwiftUI

/// Cloudns 全局语义色与主题 Token (严格遵循 Apple HIG 层次体系)
public enum CloudnsColor {
    // MARK: - Brand Colors
    /// 品牌主色 (Cloudflare Blue: #2673F2)
    public static let brand = Color(red: 0.15, green: 0.45, blue: 0.95)
    /// 品牌深色 (用于渐变深色端: #144CBF)
    public static let brandDark = Color(red: 0.08, green: 0.30, blue: 0.75)
    /// 品牌强调橙色 (Cloudflare Orange: #FA7317)
    public static let brandAccent = Color(red: 0.98, green: 0.45, blue: 0.09)
    
    // MARK: - Semantic Status Colors
    /// 代理状态色 (橙色：Cloudflare Proxied CDN/WAF 开启)
    public static let proxied = Color.orange
    /// 仅 DNS 解析状态色 (灰色：仅 DNS 绕过 CDN)
    public static let dnsOnly = Color.gray
    /// 成功/正常状态色 (绿色：Active、正常运行、SSL 有效)
    public static let success = Color.green
    /// 警告状态色 (橙色：Pending 待处理、降级运行)
    public static let warning = Color.orange
    /// 危险/错误状态色 (红色：Error 异常、攻击告警、删除)
    public static let danger = Color.red
    /// 信息状态色 (蓝色：提示、进行中)
    public static let info = Color.blue
    
    // MARK: - Muted Status Tints (用于呼吸灯背景、Badge 浅色底座)
    /// 代理状态浅色背景底座 (12% 不透明度)
    public static let proxiedMuted = Color.orange.opacity(0.12)
    /// 仅 DNS 状态浅色背景底座 (14% 不透明度)
    public static let dnsOnlyMuted = Color.gray.opacity(0.14)
    /// 成功状态浅色背景底座 (14% 不透明度)
    public static let successMuted = Color.green.opacity(0.14)
    /// 警告状态浅色背景底座 (14% 不透明度)
    public static let warningMuted = Color.orange.opacity(0.14)
    /// 危险状态浅色背景底座 (14% 不透明度)
    public static let dangerMuted = Color.red.opacity(0.14)
    /// 信息状态浅色背景底座 (14% 不透明度)
    public static let infoMuted = Color.blue.opacity(0.14)
    /// 品牌色浅色背景底座 (14% 不透明度)
    public static let brandMuted = Color(red: 0.15, green: 0.45, blue: 0.95).opacity(0.14)
    
    // MARK: - Surfaces & Backgrounds
    /// 页面大背景色 (系统分组背景色：iOS System Grouped Background)
    public static let groupedBackground = Color(UIColor.systemGroupedBackground)
    /// 二级分组背景色 (标准卡片背景色：iOS Secondary System Grouped Background)
    public static let secondaryGroupedBackground = Color(UIColor.secondarySystemGroupedBackground)
    /// 三级分组背景色 (嵌套内层卡片：iOS Tertiary System Grouped Background)
    public static let tertiaryGroupedBackground = Color(UIColor.tertiarySystemGroupedBackground)
    /// 标准卡片背景色别名
    public static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    /// Chip / 小标签灰色背景底色
    public static let chipBackground = Color(UIColor.tertiarySystemFill)
    
    // MARK: - System Fills (HIG 4-tier Fill Hierarchy)
    /// 一级系统填充色 (主要容器或输入背景)
    public static let primaryFill = Color(UIColor.systemFill)
    /// 二级系统填充色 (中度对比填充)
    public static let secondaryFill = Color(UIColor.secondarySystemFill)
    /// 三级系统填充色 (次要元素/Chip/搜索条背景)
    public static let tertiaryFill = Color(UIColor.tertiarySystemFill)
    /// 四级系统填充色 (微弱极浅填充)
    public static let quaternaryFill = Color(UIColor.quaternarySystemFill)
    
    // MARK: - Text & Label Hierarchy
    /// 一级标题与主要文本 (系统 primary，亮暗自动反转)
    public static let textPrimary = Color.primary
    /// 二级副标题与辅助说明 (系统 secondary)
    public static let textSecondary = Color.secondary
    /// 三级占位符与禁用文字 (系统 tertiaryLabel)
    public static let textTertiary = Color(UIColor.tertiaryLabel)
    /// 四级水印与微弱装饰文字 (系统 quaternaryLabel)
    public static let textQuaternary = Color(UIColor.quaternaryLabel)
    
    // MARK: - Separators & Outlines
    /// 标准列表分割线与描边 (系统 separator)
    public static let separator = Color(UIColor.separator)
    /// 不透明分割线 (系统 opaqueSeparator)
    public static let opaqueSeparator = Color(UIColor.opaqueSeparator)
    
    // MARK: - Brand Gradients
    /// 品牌主打渐变橙色 (用于高光徽章、VIP 标识、强调按钮)
    public static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [brandAccent, Color(red: 1.0, green: 0.60, blue: 0.18)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// 品牌科技渐变蓝色 (用于 Hero 头部大卡片、开发者主页)
    public static var blueGradient: LinearGradient {
        LinearGradient(
            colors: [brand, Color(red: 0.20, green: 0.60, blue: 1.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
