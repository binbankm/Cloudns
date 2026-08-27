import SwiftUI

/// Cloudns 全局排版样式 Token
public enum CloudnsTypography {
    public static let largeTitle: Font = .largeTitle.weight(.bold)
    public static let title: Font = .title.weight(.bold)
    public static let title2: Font = .title2.weight(.bold)
    public static let title3: Font = .title3.weight(.semibold)
    public static let headline: Font = .headline
    public static let subheadline: Font = .subheadline
    public static let body: Font = .body
    public static let callout: Font = .callout
    public static let footnote: Font = .footnote
    public static let caption: Font = .caption
    public static let caption2: Font = .caption2
    
    // Monospaced Numbers
    public static func monospaced(_ font: Font = .body) -> Font {
        font.monospacedDigit()
    }
}
