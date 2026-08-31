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
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? opacity : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed && haptic {
                    HIGFeedback.selection()
                }
            }
    }
}

/// Card Pressable Style tailored for Bento Grid and Metric Cards
public struct HIGCardButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    HIGFeedback.selection()
                }
            }
    }
}

/// Primary Action Button Style with Apple-standard filled pill/rounded rectangle and medium impact
public struct HIGPrimaryActionButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    let cornerRadius: CGFloat
    
    public init(
        backgroundColor: Color = .blue,
        foregroundColor: Color = .white,
        cornerRadius: CGFloat = 12
    ) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.cornerRadius = cornerRadius
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(foregroundColor)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
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
    
    static func higPrimaryAction(backgroundColor: Color = .blue, cornerRadius: CGFloat = 12) -> HIGPrimaryActionButtonStyle {
        HIGPrimaryActionButtonStyle(backgroundColor: backgroundColor, cornerRadius: cornerRadius)
    }
}
