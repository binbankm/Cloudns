import SwiftUI
import UIKit

// MARK: - Gentle Color Tokens

/// Global Ultra-Gentle & Cozy HIG Color Palette
/// Designed for maximum warmth, eye-care, and Apple Human Interface Guidelines compliance.
public enum GentleColor {
    // MARK: - Canvas & Card Backgrounds

    /// Primary background: Oat Milk Beige in light mode (#F7F4EE), Midnight Graphite in dark mode (#1C1C1E)
    public static var background: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0)
                : UIColor(red: 247 / 255, green: 244 / 255, blue: 238 / 255, alpha: 1.0)
        })
    }

    /// Floating card surface: Pure Warm Cream in light mode (#FDFBF7), Dark Slate Gray in dark mode (#2C2C2E)
    public static var cardSurface: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 44 / 255, green: 44 / 255, blue: 46 / 255, alpha: 1.0)
                : UIColor(red: 253 / 255, green: 251 / 255, blue: 247 / 255, alpha: 1.0)
        })
    }

    /// Secondary card surface for nested elements: Soft Canvas (#F2EFE8 / #3A3A3C)
    public static var cardSurfaceSecondary: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 58 / 255, green: 58 / 255, blue: 60 / 255, alpha: 1.0)
                : UIColor(red: 242 / 255, green: 239 / 255, blue: 232 / 255, alpha: 1.0)
        })
    }

    /// Tertiary card surface for inner controls, tags, and chips: (#EAE6DD / #48484A)
    public static var cardSurfaceTertiary: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 72 / 255, green: 72 / 255, blue: 74 / 255, alpha: 1.0)
                : UIColor(red: 234 / 255, green: 230 / 255, blue: 221 / 255, alpha: 1.0)
        })
    }

    // MARK: - Borders & Separators

    /// Gentle subtle card border stroke
    public static var border: Color {
        Color(uiColor: UIColor { trait in
            if trait.accessibilityContrast == .high {
                return trait.userInterfaceStyle == .dark
                    ? UIColor.white.withAlphaComponent(0.3)
                    : UIColor.black.withAlphaComponent(0.25)
            }
            return trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.06)
                : UIColor.black.withAlphaComponent(0.035)
        })
    }

    /// Hairline separator divider line
    public static var separator: Color {
        Color(uiColor: UIColor { trait in
            if trait.accessibilityContrast == .high {
                return trait.userInterfaceStyle == .dark
                    ? UIColor.white.withAlphaComponent(0.35)
                    : UIColor.black.withAlphaComponent(0.3)
            }
            return trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.10)
                : UIColor.black.withAlphaComponent(0.07)
        })
    }

    // MARK: - Typography Colors

    /// Primary text: Deep Warm Charcoal in light mode (#2E2A27), Warm Off-White in dark mode (#F5F5F7)
    public static var textPrimary: Color {
        Color(uiColor: UIColor { trait in
            if trait.accessibilityContrast == .high {
                return trait.userInterfaceStyle == .dark ? .white : .black
            }
            return trait.userInterfaceStyle == .dark
                ? UIColor(red: 245 / 255, green: 245 / 255, blue: 247 / 255, alpha: 1.0)
                : UIColor(red: 46 / 255, green: 42 / 255, blue: 39 / 255, alpha: 1.0)
        })
    }

    /// Secondary text: Gentle Muted Slate Gray (#8E8883 / #98989D)
    public static var textSecondary: Color {
        Color(uiColor: UIColor { trait in
            if trait.accessibilityContrast == .high {
                return trait.userInterfaceStyle == .dark
                    ? UIColor(red: 200 / 255, green: 200 / 255, blue: 205 / 255, alpha: 1.0)
                    : UIColor(red: 90 / 255, green: 85 / 255, blue: 80 / 255, alpha: 1.0)
            }
            return trait.userInterfaceStyle == .dark
                ? UIColor(red: 152 / 255, green: 152 / 255, blue: 157 / 255, alpha: 1.0)
                : UIColor(red: 142 / 255, green: 136 / 255, blue: 131 / 255, alpha: 1.0)
        })
    }

    /// Tertiary text for subtle hints and metadata: (#B5AFA9 / #636366)
    public static var textTertiary: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 99 / 255, green: 99 / 255, blue: 102 / 255, alpha: 1.0)
                : UIColor(red: 181 / 255, green: 175 / 255, blue: 169 / 255, alpha: 1.0)
        })
    }

    // MARK: - Accent & Brand

    /// Warm Sunset Amber: Soft, gentle Cloudflare brand orange (#E87A1E)
    public static var accent: Color {
        Color(red: 232 / 255, green: 122 / 255, blue: 30 / 255)
    }

    /// Pure crisp white text or icons on warm accent surfaces (#FFFFFF)
    public static var textOnAccent: Color {
        Color.white
    }

    /// Secondary accent: Pastel Apricot Glow (#F2A054)
    public static var accentSecondary: Color {
        Color(red: 242 / 255, green: 160 / 255, blue: 84 / 255)
    }

    // MARK: - Semantic Status & Badge Colors (AGENTS.md 对齐)

    /// 正常生效 / Active: 低饱和马卡龙鼠尾草绿 (#5B8E7D)
    public static var statusActive: Color {
        Color(uiColor: UIColor { trait in
            if trait.accessibilityContrast == .high {
                return trait.userInterfaceStyle == .dark
                    ? UIColor(red: 120 / 255, green: 185 / 255, blue: 160 / 255, alpha: 1.0)
                    : UIColor(red: 70 / 255, green: 120 / 255, blue: 100 / 255, alpha: 1.0)
            }
            return trait.userInterfaceStyle == .dark
                ? UIColor(red: 108 / 255, green: 165 / 255, blue: 146 / 255, alpha: 1.0)
                : UIColor(red: 91 / 255, green: 142 / 255, blue: 125 / 255, alpha: 1.0)
        })
    }

    /// 代理状态 / Proxied: 柔光蜜桃暖橙 (#E08A58)
    public static var statusProxied: Color {
        Color(uiColor: UIColor { trait in
            if trait.accessibilityContrast == .high {
                return trait.userInterfaceStyle == .dark
                    ? UIColor(red: 245 / 255, green: 165 / 255, blue: 115 / 255, alpha: 1.0)
                    : UIColor(red: 200 / 255, green: 115 / 255, blue: 65 / 255, alpha: 1.0)
            }
            return trait.userInterfaceStyle == .dark
                ? UIColor(red: 235 / 255, green: 153 / 255, blue: 106 / 255, alpha: 1.0)
                : UIColor(red: 224 / 255, green: 138 / 255, blue: 88 / 255, alpha: 1.0)
        })
    }

    /// 危险操作 / Delete / Destructive: 温和珊瑚粉红 (#D96B6B)
    public static var statusDanger: Color {
        Color(uiColor: UIColor { trait in
            if trait.accessibilityContrast == .high {
                return trait.userInterfaceStyle == .dark
                    ? UIColor(red: 245 / 255, green: 135 / 255, blue: 135 / 255, alpha: 1.0)
                    : UIColor(red: 195 / 255, green: 85 / 255, blue: 85 / 255, alpha: 1.0)
            }
            return trait.userInterfaceStyle == .dark
                ? UIColor(red: 229 / 255, green: 123 / 255, blue: 123 / 255, alpha: 1.0)
                : UIColor(red: 217 / 255, green: 107 / 255, blue: 107 / 255, alpha: 1.0)
        })
    }

    /// 警告 / 待生效 / Warning: 柔光杏金 (#DF9B43)
    public static var statusWarning: Color {
        Color(uiColor: UIColor { trait in
            if trait.accessibilityContrast == .high {
                return trait.userInterfaceStyle == .dark
                    ? UIColor(red: 245 / 255, green: 185 / 255, blue: 95 / 255, alpha: 1.0)
                    : UIColor(red: 200 / 255, green: 135 / 255, blue: 45 / 255, alpha: 1.0)
            }
            return trait.userInterfaceStyle == .dark
                ? UIColor(red: 235 / 255, green: 171 / 255, blue: 87 / 255, alpha: 1.0)
                : UIColor(red: 223 / 255, green: 155 / 255, blue: 67 / 255, alpha: 1.0)
        })
    }

    // MARK: - Raw Palette Colors (基础色板)

    /// Muted Pastel Sage Green (#5B8E7D)
    public static var sageGreen: Color {
        statusActive
    }

    /// Warm Glowing Peach Orange (#E08A58)
    public static var peachOrange: Color {
        statusProxied
    }

    /// Muted Coral Red (#D96B6B)
    public static var coralRed: Color {
        statusDanger
    }

    /// Soft Apricot Gold (#DF9B43)
    public static var apricotGold: Color {
        statusWarning
    }

    /// Calm Sky Blue for information/CNAME records (#6593B2)
    public static var skyBlue: Color {
        Color(red: 101 / 255, green: 147 / 255, blue: 178 / 255)
    }

    /// Gentle Lavender for MX / special records (#8C7CA8)
    public static var lavender: Color {
        Color(red: 140 / 255, green: 124 / 255, blue: 168 / 255)
    }
}

/// AGENTS.md 兼容性别名
public typealias GentleColors = GentleColor
