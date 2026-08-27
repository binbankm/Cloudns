import SwiftUI

/// Cloudns 全局排版样式 Token (严格遵循 Apple HIG Dynamic Type 规范)
public enum CloudnsTypography {
    // MARK: - Titles & Headings
    /// 大标题 (34pt 默认基准，用于导航栏大标题或 Hero 界面)
    public static let largeTitle: Font = .system(.largeTitle, design: .default, weight: .bold)
    /// 一级标题 (28pt 默认基准)
    public static let title: Font = .system(.title, design: .default, weight: .bold)
    /// 二级标题 (22pt 默认基准，模态弹窗或卡片一级标题)
    public static let title2: Font = .system(.title2, design: .default, weight: .bold)
    /// 三级标题 (20pt 默认基准，Section 或子卡片标题)
    public static let title3: Font = .system(.title3, design: .default, weight: .semibold)
    
    // MARK: - Content Hierarchy
    /// 重点正文标题 (17pt 默认基准，列表项核心文字)
    public static let headline: Font = .system(.headline, design: .default, weight: .semibold)
    /// 次要内容 / 列表次标题 (15pt 默认基准)
    public static let subheadline: Font = .system(.subheadline, design: .default, weight: .regular)
    /// 标准正文 (17pt 默认基准)
    public static let body: Font = .system(.body, design: .default, weight: .regular)
    /// 突出呼出文本 (16pt 默认基准)
    public static let callout: Font = .system(.callout, design: .default, weight: .regular)
    /// 脚注小字 (13pt 默认基准)
    public static let footnote: Font = .system(.footnote, design: .default, weight: .regular)
    /// 说明标签文字 (12pt 默认基准)
    public static let caption: Font = .system(.caption, design: .default, weight: .regular)
    /// 超微标签文字 (11pt 默认基准)
    public static let caption2: Font = .system(.caption2, design: .default, weight: .regular)
    
    // MARK: - Monospaced & Code (DNS / IP / Hash / Numbers)
    /// 等宽数字字体（防止秒表/数字翻滚时宽度跳动）
    public static func monospaced(_ font: Font = .body) -> Font {
        font.monospacedDigit()
    }
    
    /// 代码 / DNS 记录 / API Key 专用等宽字体
    public static let code: Font = .system(.footnote, design: .monospaced, weight: .regular)
    public static let codeSmall: Font = .system(.caption2, design: .monospaced, weight: .regular)
    
    // MARK: - Rounded Numeric (仪表盘与指标大数)
    public static let metricLarge: Font = .system(.title, design: .rounded, weight: .bold).monospacedDigit()
    public static let metricMedium: Font = .system(.title2, design: .rounded, weight: .bold).monospacedDigit()
    public static let metricSmall: Font = .system(.headline, design: .rounded, weight: .bold).monospacedDigit()
}
