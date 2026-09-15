import SwiftUI

// MARK: - Gentle Shadow Tokens (Feather-Soft HIG Shadows)

/// Unified feather-soft ambient shadows that eliminate harsh dark borders.
public enum GentleShadow {
    /// Standard ambient card shadow (AGENTS.md: opacity 0.035, radius 10, y 3)
    public static func card(colorScheme: ColorScheme) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        (
            color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.035),
            radius: 10,
            x: 0,
            y: 3
        )
    }

    /// Subtle compact shadow for floating pills and search inputs
    public static func subtle(colorScheme: ColorScheme) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        (
            color: Color.black.opacity(colorScheme == .dark ? 0.20 : 0.025),
            radius: 6,
            x: 0,
            y: 2
        )
    }

    /// Warm amber ambient halo glow
    public static func amberGlow(colorScheme: ColorScheme) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        (
            color: GentleColor.accent.opacity(colorScheme == .dark ? 0.16 : 0.09),
            radius: 12,
            x: 0,
            y: 4
        )
    }
}

public extension View {
    /// Applies standard feather-soft card shadow
    func gentleCardShadow() -> some View {
        shadow(
            color: Color.black.opacity(0.035),
            radius: 10,
            x: 0,
            y: 3
        )
    }

    /// Applies subtle pill or control shadow
    func gentleSubtleShadow() -> some View {
        shadow(
            color: Color.black.opacity(0.025),
            radius: 6,
            x: 0,
            y: 2
        )
    }
}
