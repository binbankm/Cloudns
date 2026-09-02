import SwiftUI

// MARK: - Apple HIG Standard Card Modifier (Bento & Inset Grouped Card)
// Provides consistent continuous corner radius, dynamic semantic surfaces, and hairline border

public struct HIGCardModifier: ViewModifier {
    public let cornerRadius: CGFloat
    public let padding: CGFloat
    public let isElevated: Bool
    
    public init(
        cornerRadius: CGFloat = HIGTokens.Radius.card,
        padding: CGFloat = HIGTokens.Spacing.lg,
        isElevated: Bool = false
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.isElevated = isElevated
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.higCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.higCardBorder, lineWidth: HIGTokens.Elevation.hairlineStroke)
            )
            .shadow(
                color: isElevated ? Color.black.opacity(0.04) : .clear,
                radius: HIGTokens.Elevation.cardShadowRadius,
                x: 0,
                y: HIGTokens.Elevation.cardShadowY
            )
    }
}

public extension View {
    /// Applies Apple HIG canonical card container styling
    func higCardStyle(
        cornerRadius: CGFloat = HIGTokens.Radius.card,
        padding: CGFloat = HIGTokens.Spacing.lg,
        isElevated: Bool = false
    ) -> some View {
        self.modifier(
            HIGCardModifier(
                cornerRadius: cornerRadius,
                padding: padding,
                isElevated: isElevated
            )
        )
    }
}
