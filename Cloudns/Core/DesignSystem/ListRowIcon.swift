import SwiftUI

// MARK: - Apple HIG Standard List Row Icon & Account Avatar
// Strict 30×30 pt continuous curvature container and deterministic gradient avatar

public struct ListRowIcon: View {
    public let icon: String
    public let color: Color
    public var size: CGFloat = HIGTokens.Size.listRowIcon
    public var cornerRadius: CGFloat = HIGTokens.Radius.listIcon
    
    public init(
        icon: String,
        color: Color,
        size: CGFloat = HIGTokens.Size.listRowIcon,
        cornerRadius: CGFloat = HIGTokens.Radius.listIcon
    ) {
        self.icon = icon
        self.color = color
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        Image(systemName: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
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
        size: CGFloat = HIGTokens.Size.avatarSmall,
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
            return HIGTypography.title2
        } else if size >= 40 {
            return HIGTypography.headline
        } else if size >= 30 {
            return HIGTypography.subheadline
        } else {
            return HIGTypography.caption
        }
    }
    
    public static func color(for string: String) -> Color {
        guard !string.isEmpty else { return .orange }
        let hash = abs(string.hashValue)
        return avatarColors[hash % avatarColors.count]
    }
}
