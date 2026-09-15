import SwiftUI

// MARK: - Gentle Badge Type

public enum GentleBadgeType {
    case active
    case proxied
    case warning
    case danger
    case custom(color: Color)

    public var tintColor: Color {
        switch self {
        case .active:
            GentleColor.statusActive
        case .proxied:
            GentleColor.statusProxied
        case .warning:
            GentleColor.statusWarning
        case .danger:
            GentleColor.statusDanger
        case let .custom(color):
            color
        }
    }
}

// MARK: - Gentle Badge Component (Apple HIG Compliant)

public struct GentleBadge: View {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    public let titleKey: LocalizedStringKey
    public var iconName: String?
    public var badgeType: GentleBadgeType

    public init(
        _ titleKey: LocalizedStringKey,
        iconName: String? = nil,
        type: GentleBadgeType = .active
    ) {
        self.titleKey = titleKey
        self.iconName = iconName
        self.badgeType = type
    }

    public init<S: StringProtocol>(
        _ title: S,
        iconName: String? = nil,
        type: GentleBadgeType = .active
    ) {
        self.titleKey = LocalizedStringKey(String(title))
        self.iconName = iconName
        self.badgeType = type
    }

    private var backgroundOpacity: Double {
        colorSchemeContrast == .increased ? 0.22 : 0.12
    }

    public var body: some View {
        HStack(spacing: GentleSpacing.xxs) {
            if let iconName {
                Image(systemName: iconName)
                    .font(GentleTypography.captionSmall)
                    .imageScale(.small)
                    .accessibilityHidden(true)
            }
            Text(titleKey)
                .font(GentleTypography.captionSmall)
                .lineLimit(1)
        }
        .foregroundStyle(badgeType.tintColor)
        .padding(.horizontal, 9)
        .padding(.vertical, 4.5)
        .background(badgeType.tintColor.opacity(backgroundOpacity))
        .overlay(
            Capsule()
                .stroke(
                    colorSchemeContrast == .increased
                        ? badgeType.tintColor.opacity(0.4)
                        : Color.clear,
                    lineWidth: 1
                )
        )
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(titleKey))
        .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    VStack(spacing: 12) {
        GentleBadge("Active", iconName: "checkmark", type: .active)
        GentleBadge("Proxied", iconName: "cloud.fill", type: .proxied)
        GentleBadge("Pending", iconName: "clock.fill", type: .warning)
        GentleBadge("Delete", iconName: "trash.fill", type: .danger)
    }
    .padding()
    .background(GentleColor.background)
}
