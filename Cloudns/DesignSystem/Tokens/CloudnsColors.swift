import SwiftUI

/// Cloudns 全局语义色 Token
public enum CloudnsColor {
    // MARK: - Brand Colors
    public static let brand = Color(red: 0.15, green: 0.45, blue: 0.95)
    public static let brandDark = Color(red: 0.08, green: 0.30, blue: 0.75)
    public static let brandAccent = Color(red: 0.98, green: 0.45, blue: 0.09) // Cloudflare Orange
    
    // MARK: - Semantic Status Colors
    public static let proxied = Color.orange
    public static let dnsOnly = Color.gray
    public static let success = Color.green
    public static let warning = Color.orange
    public static let danger = Color.red
    public static let info = Color.blue
    
    // MARK: - Surfaces & Backgrounds
    public static let groupedBackground = Color(UIColor.systemGroupedBackground)
    public static let secondaryGroupedBackground = Color(UIColor.secondarySystemGroupedBackground)
    public static let tertiaryGroupedBackground = Color(UIColor.tertiarySystemGroupedBackground)
    public static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    public static let chipBackground = Color(UIColor.tertiarySystemFill)
    public static let separator = Color(UIColor.separator)
    public static let opaqueSeparator = Color(UIColor.opaqueSeparator)
}
