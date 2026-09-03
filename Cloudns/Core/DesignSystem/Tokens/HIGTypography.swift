import SwiftUI

// MARK: - Apple HIG Canonical Typography Tokens
// Standard dynamic type styles and data alignment helpers

public enum HIGTypography {
    
    /// Canonical large title style
    public static let largeTitle: Font = .largeTitle.weight(.bold)
    
    /// Canonical title style
    public static let title: Font = .title.weight(.bold)
    
    /// Canonical title 2 style
    public static let title2: Font = .title2.weight(.bold)
    
    /// Canonical title 3 style
    public static let title3: Font = .title3.weight(.semibold)
    
    /// Canonical headline style for lists and cards
    public static let headline: Font = .headline
    
    /// Canonical body style
    public static let body: Font = .body
    
    /// Canonical subheadline style
    public static let subheadline: Font = .subheadline
    
    /// Canonical footnote style
    public static let footnote: Font = .footnote
    
    /// Canonical caption and caption2 styles
    public static let caption: Font = .caption
    public static let caption2: Font = .caption2
}

// MARK: - Monospaced & Data Alignment Extensions

public extension View {
    /// Monospaced digits modifier for network metrics, IP addresses, TTL, and hashes
    func higMonospacedDigits() -> some View {
        self.monospacedDigit()
    }
}
