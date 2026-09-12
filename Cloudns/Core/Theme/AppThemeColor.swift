import SwiftUI

// MARK: - App Theme Accent Color Model

public enum AppThemeColor: String, CaseIterable, Identifiable, Sendable {
    case orange
    case blue
    case green
    case purple
    case indigo
    case teal
    case mint
    case pink
    case red
    case custom

    public var id: String {
        rawValue
    }

    public var displayName: LocalizedStringKey {
        switch self {
        case .orange: "Cloudflare Orange"
        case .blue: "Aurora Blue"
        case .green: "Emerald Green"
        case .purple: "Electric Purple"
        case .indigo: "Deep Indigo"
        case .teal: "Cyan Teal"
        case .mint: "Fresh Mint"
        case .pink: "Rose Pink"
        case .red: "Ruby Red"
        case .custom: "Custom"
        }
    }

    public var presetColor: Color {
        switch self {
        case .orange:
            Color(uiColor: UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: 0.96, green: 0.50, blue: 0.12, alpha: 1.0) // Luminous Cloudflare Brand Orange
                    : UIColor(red: 0.88, green: 0.40, blue: 0.04, alpha: 1.0) // Deep High-Contrast Orange (WCAG AA)
            })
        case .blue: .blue
        case .green: .green
        case .purple: .purple
        case .indigo: .indigo
        case .teal: .teal
        case .mint: .mint
        case .pink: .pink
        case .red: .red
        case .custom: .orange
        }
    }

    @MainActor
    public var color: Color {
        if self == .custom {
            return ThemeManager.shared.customColor
        }
        return presetColor
    }
}
