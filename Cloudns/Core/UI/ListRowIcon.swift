import SwiftUI

// MARK: - Apple HIG Standard List Row Icon & Account Avatar

// Strict 30×30 pt continuous curvature container and deterministic gradient avatar

public struct ListRowIcon: View {
    public let icon: String
    public let color: Color
    public var size: CGFloat
    public var cornerRadius: CGFloat

    public init(
        icon: String,
        color: Color,
        size: CGFloat = 30,
        cornerRadius: CGFloat = 7
    ) {
        self.icon = icon
        self.color = color
        self.size = size
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: effectiveGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if icon == "github" || icon == "github.mark" {
                Image("github")
                    .renderingMode(.template)
                    .resizable().scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: glyphBoxSize, height: glyphBoxSize, alignment: .center)
            } else {
                Image(systemName: icon)
                    .symbolRenderingMode(.hierarchical)
                    .font(iconFont)
                    .foregroundStyle(.white)
                    .frame(width: glyphBoxSize, height: glyphBoxSize, alignment: .center)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var effectiveGradientColors: [Color] {
        if color == .primary {
            return [Color(red: 0.24, green: 0.25, blue: 0.28), Color(red: 0.16, green: 0.17, blue: 0.20)]
        }
        return [color, color.opacity(0.88)]
    }

    private var glyphBoxSize: CGFloat {
        if size >= 44 {
            24
        } else if size >= 32 {
            18
        } else if size >= 28 {
            16
        } else {
            13
        }
    }

    private var iconFont: Font {
        if size >= 44 {
            .system(size: 20, weight: .semibold)
        } else if size >= 32 {
            .system(size: 16, weight: .semibold)
        } else if size >= 28 {
            .system(size: 14.5, weight: .semibold)
        } else {
            .system(size: 12, weight: .semibold)
        }
    }
}

// MARK: - HeroHeaderEmblemView (Sub-Page Floating Island Hero Emblem)

public struct HeroHeaderEmblemView: View {
    public let icon: String
    public let primaryColor: Color
    public var secondaryColor: Color?
    public var size: CGFloat

    public init(
        icon: String,
        primaryColor: Color,
        secondaryColor: Color? = nil,
        size: CGFloat = 64
    ) {
        self.icon = icon
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.size = size
    }

    public var body: some View {
        let secColor = secondaryColor ?? primaryColor
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [primaryColor, secColor.opacity(0.88)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: primaryColor.opacity(0.24), radius: 8, x: 0, y: 4)

            Image(systemName: icon)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size * 0.55, height: size * 0.55, alignment: .center)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - AccountAvatarView

public struct AccountAvatarView: View {
    public let identifier: String
    public let size: CGFloat
    public let showShadow: Bool

    private static let avatarColors: [Color] = [
        .orange, .blue, .purple, .teal, .indigo, .pink, .green
    ]

    public init(
        identifier: String,
        size: CGFloat = 34,
        showShadow: Bool = true
    ) {
        self.identifier = identifier
        self.size = size
        self.showShadow = showShadow
    }

    public var body: some View {
        let initial = String(identifier.prefix(1)).uppercased()
        let color = AccountAvatarView.color(for: identifier)

        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(
                    color: showShadow ? color.opacity(0.28) : .clear,
                    radius: size > 40 ? 6 : 3,
                    x: 0,
                    y: 2
                )

            Text(initial.isEmpty ? "?" : initial)
                .font(fontSize.weight(.bold))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }

    private var fontSize: Font {
        if size >= 50 {
            .title2
        } else if size >= 40 {
            .headline
        } else if size >= 30 {
            .subheadline
        } else {
            .caption
        }
    }

    public static func color(for string: String) -> Color {
        guard !string.isEmpty else { return .orange }
        let hash = abs(string.hashValue)
        return avatarColors[hash % avatarColors.count]
    }
}
