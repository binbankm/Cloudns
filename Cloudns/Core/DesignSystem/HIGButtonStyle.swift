import SwiftUI

// MARK: - Apple HIG Standard Button Styles

/// Apple-style interactive scale animation button style (0.96 scale on press with spring)
public struct HIGPressableButtonStyle: ButtonStyle {
    let scale: CGFloat
    let opacity: Double
    let haptic: Bool
    
    public init(scale: CGFloat = 0.96, opacity: Double = 0.88, haptic: Bool = true) {
        self.scale = scale
        self.opacity = opacity
        self.haptic = haptic
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        HIGPressableBody(configuration: configuration, scale: scale, opacity: opacity, haptic: haptic)
    }
}

private struct HIGPressableBody: View {
    let configuration: ButtonStyle.Configuration
    let scale: CGFloat
    let opacity: Double
    let haptic: Bool
    
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        configuration.label
            .scaleEffect(configuration.isPressed && isEnabled ? scale : 1.0)
            .opacity(isEnabled ? (configuration.isPressed ? opacity : 1.0) : 0.38)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed && haptic && isEnabled {
                    HIGFeedback.selection()
                }
            }
    }
}

/// Card Pressable Style tailored for Bento Grid and Metric Cards
public struct HIGCardButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        HIGCardBody(configuration: configuration)
    }
}

private struct HIGCardBody: View {
    let configuration: ButtonStyle.Configuration
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        configuration.label
            .scaleEffect(configuration.isPressed && isEnabled ? 0.97 : 1.0)
            .opacity(isEnabled ? (configuration.isPressed ? 0.92 : 1.0) : 0.45)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed && isEnabled {
                    HIGFeedback.selection()
                }
            }
    }
}

/// Primary Action Button Style with Apple-standard filled pill/rounded rectangle and medium impact
public struct HIGPrimaryActionButtonStyle: ButtonStyle {
    let backgroundColor: Color?
    let foregroundColor: Color
    let cornerRadius: CGFloat
    
    public init(
        backgroundColor: Color? = nil,
        foregroundColor: Color = .white,
        cornerRadius: CGFloat = 12
    ) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.cornerRadius = cornerRadius
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        HIGPrimaryActionBody(
            configuration: configuration,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            cornerRadius: cornerRadius
        )
    }
}

private struct HIGPrimaryActionBody: View {
    let configuration: ButtonStyle.Configuration
    let backgroundColor: Color?
    let foregroundColor: Color
    let cornerRadius: CGFloat
    
    @Environment(\.isEnabled) private var isEnabled
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var effectiveBackground: Color {
        backgroundColor ?? themeManager.currentColor.color
    }
    
    var body: some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(isEnabled ? foregroundColor : Color(.tertiaryLabel))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(isEnabled ? effectiveBackground : Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed && isEnabled ? 0.96 : 1.0)
            .opacity(configuration.isPressed && isEnabled ? 0.88 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed && isEnabled {
                    HIGFeedback.impact(.medium)
                }
            }
    }
}

public extension ButtonStyle where Self == HIGPressableButtonStyle {
    static var higPressable: HIGPressableButtonStyle {
        HIGPressableButtonStyle()
    }
}

public extension ButtonStyle where Self == HIGCardButtonStyle {
    static var higCard: HIGCardButtonStyle {
        HIGCardButtonStyle()
    }
}

public extension ButtonStyle where Self == HIGPrimaryActionButtonStyle {
    static var higPrimaryAction: HIGPrimaryActionButtonStyle {
        HIGPrimaryActionButtonStyle()
    }
    
    static func higPrimaryAction(backgroundColor: Color? = nil, cornerRadius: CGFloat = 12) -> HIGPrimaryActionButtonStyle {
        HIGPrimaryActionButtonStyle(backgroundColor: backgroundColor, cornerRadius: cornerRadius)
    }
}
