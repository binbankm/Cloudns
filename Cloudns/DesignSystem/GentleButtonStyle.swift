import SwiftUI

// MARK: - Gentle Primary Button Style (Warm Sunset Amber)

public struct GentlePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public var cornerRadius: CGFloat
    public var height: CGFloat

    public init(
        cornerRadius: CGFloat = GentleCornerRadius.xl,
        height: CGFloat = 50
    ) {
        self.cornerRadius = cornerRadius
        self.height = height
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GentleTypography.buttonLabel)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                isEnabled
                    ? GentleColor.accent
                    : GentleColor.textSecondary.opacity(0.3)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: isEnabled ? GentleColor.accent.opacity(0.25) : Color.clear,
                radius: 8,
                x: 0,
                y: 3
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(GentleAnimation.spring, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed, isEnabled {
                    GentleHaptics.soft()
                }
            }
    }
}

// MARK: - Gentle Secondary Button Style

public struct GentleSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public var cornerRadius: CGFloat
    public var height: CGFloat

    public init(
        cornerRadius: CGFloat = GentleCornerRadius.xl,
        height: CGFloat = 50
    ) {
        self.cornerRadius = cornerRadius
        self.height = height
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GentleTypography.buttonLabel)
            .foregroundStyle(GentleColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(GentleColor.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(GentleColor.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(GentleAnimation.spring, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed, isEnabled {
                    GentleHaptics.selection()
                }
            }
    }
}

// MARK: - Gentle Destructive Button Style

public struct GentleDestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public var cornerRadius: CGFloat
    public var height: CGFloat

    public init(
        cornerRadius: CGFloat = GentleCornerRadius.xl,
        height: CGFloat = 50
    ) {
        self.cornerRadius = cornerRadius
        self.height = height
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GentleTypography.buttonLabel)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                isEnabled
                    ? GentleColor.statusDanger
                    : GentleColor.statusDanger.opacity(0.4)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(GentleAnimation.spring, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed, isEnabled {
                    GentleHaptics.warning()
                }
            }
    }
}

// MARK: - Gentle Loading Button

public struct GentleLoadingButton: View {
    public let title: String
    public let isLoading: Bool
    public var iconName: String?
    public var isPrimary: Bool
    public var isDestructive: Bool
    public var height: CGFloat
    public var action: () -> Void

    public init(
        _ title: String,
        isLoading: Bool = false,
        iconName: String? = nil,
        isPrimary: Bool = true,
        isDestructive: Bool = false,
        height: CGFloat = 50,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.iconName = iconName
        self.isPrimary = isPrimary
        self.isDestructive = isDestructive
        self.height = height
        self.action = action
    }

    public var body: some View {
        Button {
            guard !isLoading else { return }
            action()
        } label: {
            ZStack {
                if isLoading {
                    GentleSpinner(
                        tint: isPrimary || isDestructive ? Color.white : GentleColor.accent,
                        size: 20
                    )
                } else {
                    HStack(spacing: GentleSpacing.xs) {
                        if let iconName {
                            Image(systemName: iconName)
                                .font(GentleTypography.bodyMedium)
                        }
                        Text(LocalizedStringKey(title))
                    }
                }
            }
        }
        .disabled(isLoading)
        .modify { view in
            if isDestructive {
                view.gentleDestructiveButton(height: height)
            } else if isPrimary {
                view.gentlePrimaryButton(height: height)
            } else {
                view.gentleSecondaryButton(height: height)
            }
        }
    }
}

private extension View {
    func modify<Content: View>(@ViewBuilder transform: (Self) -> Content) -> Content {
        transform(self)
    }
}

// MARK: - View Extension

public extension View {
    func gentlePrimaryButton(
        cornerRadius: CGFloat = GentleCornerRadius.xl,
        height: CGFloat = 50
    ) -> some View {
        buttonStyle(GentlePrimaryButtonStyle(cornerRadius: cornerRadius, height: height))
    }

    func gentleSecondaryButton(
        cornerRadius: CGFloat = GentleCornerRadius.xl,
        height: CGFloat = 50
    ) -> some View {
        buttonStyle(GentleSecondaryButtonStyle(cornerRadius: cornerRadius, height: height))
    }

    func gentleDestructiveButton(
        cornerRadius: CGFloat = GentleCornerRadius.xl,
        height: CGFloat = 50
    ) -> some View {
        buttonStyle(GentleDestructiveButtonStyle(cornerRadius: cornerRadius, height: height))
    }
}
