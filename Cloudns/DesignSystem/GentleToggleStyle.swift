import SwiftUI

// MARK: - Gentle Toggle Style (Peach Orange & Sage Green Micro-Switch)

/// Custom cozy toggle style designed for Cloudflare Proxy (Peach Orange) and SSL toggles.
public struct GentleToggleStyle: ToggleStyle {
    public var onColor: Color
    public var offColor: Color

    public init(
        onColor: Color = GentleColor.statusProxied,
        offColor: Color = GentleColor.textSecondary.opacity(0.2)
    ) {
        self.onColor = onColor
        self.offColor = offColor
    }

    public func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            RoundedRectangle(cornerRadius: GentleCornerRadius.xl, style: .continuous)
                .fill(configuration.isOn ? onColor : offColor)
                .frame(width: 48, height: 28)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .padding(2.5)
                        .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1.5)
                        .offset(x: configuration.isOn ? 10 : -10)
                )
                .animation(GentleAnimation.spring, value: configuration.isOn)
                .onTapGesture {
                    configuration.isOn.toggle()
                    GentleHaptics.selection()
                }
                .accessibilityAddTraits(.isButton)
        }
    }
}

public extension ToggleStyle where Self == GentleToggleStyle {
    static var gentleProxy: GentleToggleStyle {
        GentleToggleStyle(onColor: GentleColor.statusProxied)
    }

    static var gentleActive: GentleToggleStyle {
        GentleToggleStyle(onColor: GentleColor.statusActive)
    }

    static var gentleAmber: GentleToggleStyle {
        GentleToggleStyle(onColor: GentleColor.accent)
    }
}

public extension View {
    /// Applies the gentle toggle micro-switch style
    func gentleToggle(onColor: Color = GentleColor.statusProxied) -> some View {
        toggleStyle(GentleToggleStyle(onColor: onColor))
    }
}
