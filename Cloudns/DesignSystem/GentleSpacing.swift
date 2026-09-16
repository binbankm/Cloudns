import SwiftUI

// MARK: - Gentle Spacing Tokens (AGENTS.md & HIG 8pt Grid)

/// Unified spacing tokens based on Apple HIG and 8pt rhythm grid.
/// Eliminates hardcoded magic numbers across all views.
public enum GentleSpacing {
    /// 2pt - Hairline micro spacing
    public static let micro: CGFloat = 2

    /// 4pt - Extra extra small (icon-text spacing, tight badge spacing)
    public static let xxs: CGFloat = 4

    /// 8pt - Extra small (tag spacing, compact list item padding)
    public static let xs: CGFloat = 8

    /// 12pt - Small (list card item spacing, tight stack spacing)
    public static let sm: CGFloat = 12

    /// 16pt - Medium (standard card padding, standard horizontal page margin)
    public static let md: CGFloat = 16

    /// 20pt - Large (spacious card padding, large page margin)
    public static let lg: CGFloat = 20

    /// 24pt - Extra large (section-to-section spacing)
    public static let xl: CGFloat = 24

    /// 32pt - Double extra large (grouped cards separator, header spacing)
    public static let xxl: CGFloat = 32

    /// 40pt - Huge (empty state top padding, modal bottom action clearance)
    public static let huge: CGFloat = 40

    // MARK: - Semantic Spacing Aliases (AGENTS.md 对齐)

    /// Standard card inner padding: 16pt
    public static let cardPadding: CGFloat = 16

    /// Spacious card inner padding: 20pt
    public static let cardPaddingLarge: CGFloat = 20

    /// Standard vertical spacing between list cards: 12pt
    public static let cardSpacing: CGFloat = 12

    /// Section-to-section vertical separation: 24pt
    public static let sectionSpacing: CGFloat = 24

    /// Page horizontal outer margins: 16pt
    public static let pageHorizontal: CGFloat = 16

    // MARK: - Icon Container Dimensions

    /// Compact icon container dimension: 28pt
    public static let iconSmall: CGFloat = 28

    /// Standard card tile icon container dimension: 36pt
    public static let iconMedium: CGFloat = 36

    /// Large hero icon container dimension: 40pt
    public static let iconLarge: CGFloat = 40
}
