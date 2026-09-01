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
    
    public var id: String { rawValue }
    
    public var displayName: LocalizedStringKey {
        switch self {
        case .orange: return "Cloudflare Orange"
        case .blue:   return "Aurora Blue"
        case .green:  return "Emerald Green"
        case .purple: return "Electric Purple"
        case .indigo: return "Deep Indigo"
        case .teal:   return "Cyan Teal"
        case .mint:   return "Fresh Mint"
        case .pink:   return "Rose Pink"
        case .red:    return "Ruby Red"
        }
    }
    
    public var color: Color {
        switch self {
        case .orange: return Color(red: 0.96, green: 0.50, blue: 0.12) // Cloudflare Brand Orange
        case .blue:   return .blue
        case .green:  return .green
        case .purple: return .purple
        case .indigo: return .indigo
        case .teal:   return .teal
        case .mint:   return .mint
        case .pink:   return .pink
        case .red:    return .red
        }
    }
}
