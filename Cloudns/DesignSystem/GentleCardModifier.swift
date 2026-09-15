import SwiftUI

// MARK: - Gentle Card Style Hierarchy

public enum GentleCardVariant {
    /// Standard primary floating card with feather-soft ambient shadow
    case elevated
    /// Secondary nested card for grouped rows or inset info boxes
    case secondary
    /// Flat card with subtle stroke border, no shadow
    case flat
    /// Highlighted card with warm amber ambient tint
    case highlighted
}

// MARK: - Gentle Card Modifier

public struct GentleCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    public var variant: GentleCardVariant
    public var cornerRadius: CGFloat
    public var padding: CGFloat

    public init(
        variant: GentleCardVariant = .elevated,
        cornerRadius: CGFloat = GentleCornerRadius.card,
        padding: CGFloat = GentleSpacing.cardPadding
    ) {
        self.variant = variant
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    private var backgroundColor: Color {
        switch variant {
        case .elevated:
            GentleColor.cardSurface
        case .secondary:
            GentleColor.cardSurfaceSecondary
        case .flat:
            GentleColor.cardSurface
        case .highlighted:
            GentleColor.cardSurface
        }
    }

    private var shadowColor: Color {
        guard variant == .elevated || variant == .highlighted else {
            return Color.clear
        }
        if variant == .highlighted {
            return GentleColor.accent.opacity(colorScheme == .dark ? 0.15 : 0.08)
        }
        return Color.black.opacity(colorScheme == .dark ? 0.25 : 0.035)
    }

    private var borderColor: Color {
        if colorSchemeContrast == .increased {
            return GentleColor.textSecondary.opacity(0.35)
        }
        if variant == .highlighted {
            return GentleColor.accent.opacity(0.3)
        }
        return GentleColor.border
    }

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(
                color: shadowColor,
                radius: variant == .highlighted ? 12 : 10,
                x: 0,
                y: 3
            )
    }
}

// MARK: - Interactive Button Card Style

public struct GentleCardButtonStyle: ButtonStyle {
    public var variant: GentleCardVariant
    public var cornerRadius: CGFloat
    public var padding: CGFloat

    public init(
        variant: GentleCardVariant = .elevated,
        cornerRadius: CGFloat = GentleCornerRadius.card,
        padding: CGFloat = GentleSpacing.cardPadding
    ) {
        self.variant = variant
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(GentleCardModifier(
                variant: variant,
                cornerRadius: cornerRadius,
                padding: padding
            ))
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(GentleAnimation.spring, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    GentleHaptics.soft()
                }
            }
    }
}

// MARK: - Declarative Gentle Card Container

public struct GentleCard<Content: View>: View {
    public var variant: GentleCardVariant
    public var cornerRadius: CGFloat
    public var padding: CGFloat
    @ViewBuilder public var content: () -> Content

    public init(
        variant: GentleCardVariant = .elevated,
        cornerRadius: CGFloat = GentleCornerRadius.card,
        padding: CGFloat = GentleSpacing.cardPadding,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.variant = variant
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }

    public var body: some View {
        content()
            .modifier(GentleCardModifier(
                variant: variant,
                cornerRadius: cornerRadius,
                padding: padding
            ))
    }
}

// MARK: - View Extension

public extension View {
    /// Applies the continuous squircle card with gentle ambient drop shadow and HIG rim light
    func gentleCard(
        variant: GentleCardVariant = .elevated,
        cornerRadius: CGFloat = GentleCornerRadius.card,
        padding: CGFloat = GentleSpacing.cardPadding
    ) -> some View {
        modifier(GentleCardModifier(
            variant: variant,
            cornerRadius: cornerRadius,
            padding: padding
        ))
    }

    /// Alias for gentleCard conforming to AGENTS.md style
    func gentleCardStyle(
        variant: GentleCardVariant = .elevated,
        cornerRadius: CGFloat = GentleCornerRadius.card,
        padding: CGFloat = GentleSpacing.cardPadding
    ) -> some View {
        gentleCard(variant: variant, cornerRadius: cornerRadius, padding: padding)
    }

    /// Sets the ultra-gentle oat-milk canvas background with interactive tap dismissal
    func gentleCanvas() -> some View {
        background(
            GentleColor.background
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
        )
    }
}
