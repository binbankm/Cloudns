import SwiftUI

// MARK: - Apple HIG Semantic Colors & Dynamic Theming
// Seamlessly connects dynamic user accent themes with Apple HIG semantic color tokens

public enum HIGColors {
    
    // MARK: - 1. Dynamic Theme Accent Colors
    /// Current dynamic user-selected theme accent color
    @MainActor
    public static var accent: Color {
        ThemeManager.shared.currentColor.color
    }
    
    /// 12% subtle opacity background for badges, list row icons, and active selections
    @MainActor
    public static var accentSubtle: Color {
        accent.opacity(0.12)
    }
    
    /// 25% glow opacity for card elevation and accent highlights
    @MainActor
    public static var accentGlow: Color {
        accent.opacity(0.25)
    }
    
    /// Dynamic theme gradient for primary action buttons and avatar rings
    @MainActor
    public static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accent.opacity(0.82)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - 2. Semantic Surfaces & Containers
    /// Standard card secondary background (adaptive for light and dark modes)
    public static var cardBackground: Color {
        Color(UIColor.secondarySystemGroupedBackground)
    }
    
    /// Primary grouped background color
    public static var groupBackground: Color {
        Color(UIColor.systemGroupedBackground)
    }
    
    /// Adaptive 0.5pt hairline card border color
    public static var cardBorder: Color {
        Color.primary.opacity(0.06)
    }
    
    /// Subtle secondary border color
    public static var subtleBorder: Color {
        Color.primary.opacity(0.04)
    }
    
    // MARK: - 3. Status Semantic Colors (Apple HIG Standard)
    public static let success: Color = .green
    public static let warning: Color = .orange
    public static let error: Color = .red
    public static let info: Color = .blue
    public static let neutral: Color = .secondary
}

// MARK: - Color Convenient Extensions

public extension Color {
    /// Accesses current HIG dynamic theme accent color
    @MainActor
    static var higAccent: Color {
        HIGColors.accent
    }
    
    @MainActor
    static var higAccentSubtle: Color {
        HIGColors.accentSubtle
    }
    
    /// Accesses current HIG standard card background
    static var higCardBackground: Color {
        HIGColors.cardBackground
    }
    
    /// Accesses current HIG standard grouped background
    static var higGroupBackground: Color {
        HIGColors.groupBackground
    }
    
    /// Accesses current HIG card hairline border
    static var higCardBorder: Color {
        HIGColors.cardBorder
    }
}
