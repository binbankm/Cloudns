import SwiftUI

// MARK: - Gentle Animation Tokens (AGENTS.md & HIG Springs)

/// Unified spring physics curves for cozy, responsive, and natural Apple HIG motion.
public enum GentleAnimation {
    /// Standard smooth spring for cards, toggles and state transitions (AGENTS.md: response 0.38, damping 0.82)
    public static var spring: Animation {
        .spring(response: 0.38, dampingFraction: 0.82)
    }

    /// Snappy spring for quick taps, button presses, and selection indicators
    public static var snappy: Animation {
        .spring(response: 0.28, dampingFraction: 0.76)
    }

    /// Gentle expansion spring for drawers, sheets, and notification banners
    public static var gentleExpand: Animation {
        .spring(response: 0.42, dampingFraction: 0.84)
    }

    /// Subtle breathing animation for skeletons and ambient glows
    public static var breathe: Animation {
        .easeInOut(duration: 1.4).repeatForever(autoreverses: true)
    }
}
