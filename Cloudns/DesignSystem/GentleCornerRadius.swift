import SwiftUI

// MARK: - Gentle Corner Radius Tokens (HIG Continuous Curvature)

/// Unified corner radius tokens based on Apple HIG continuous super-ellipse (Squircle).
public enum GentleCornerRadius {
    /// 4pt - Micro tags, tiny badges
    public static let micro: CGFloat = 4

    /// 6pt - Extra small (skeleton bars, subtle chips)
    public static let xs: CGFloat = 6

    /// 8pt - Small buttons, icon tiles, badge tags
    public static let sm: CGFloat = 8

    /// 12pt - Secondary elements, inner card controls
    public static let md: CGFloat = 12

    /// 14pt - Input text fields, search bars
    public static let lg: CGFloat = 14

    /// 16pt - Toggles, medium buttons
    public static let xl: CGFloat = 16

    /// 22pt - Standard card squircle (AGENTS.md 规范)
    public static let card: CGFloat = 22
    public static let xxl: CGFloat = 22

    /// 24pt - Large dialogs, bottom sheet cards (AGENTS.md 规范)
    public static let cardLarge: CGFloat = 24

    /// Full capsule / pill radius
    public static let pill: CGFloat = 999
}
