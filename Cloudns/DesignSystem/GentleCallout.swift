import SwiftUI

// MARK: - Gentle Callout Component (Inline Information Banner)

public enum GentleCalloutType {
    case info
    case success
    case warning
    case danger

    public var tintColor: Color {
        switch self {
        case .info:
            return GentleColor.accent
        case .success:
            return GentleColor.sageGreen
        case .warning:
            return GentleColor.apricotGold
        case .danger:
            return GentleColor.statusDanger
        }
    }

    public var defaultIconName: String {
        switch self {
        case .info:
            return "info.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .danger:
            return "xmark.octagon.fill"
        }
    }
}

/// An inline warm callout card for hints, cautions, and status updates inside pages or sheets.
public struct GentleCallout: View {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    public let title: String?
    public let message: String
    public let type: GentleCalloutType
    public let iconName: String?
    public var actionTitle: String?
    public var onAction: (() -> Void)?

    public init(
        title: String? = nil,
        message: String,
        type: GentleCalloutType = .info,
        iconName: String? = nil,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.type = type
        self.iconName = iconName
        self.actionTitle = actionTitle
        self.onAction = onAction
    }

    public var body: some View {
        HStack(alignment: .top, spacing: GentleSpacing.sm) {
            Image(systemName: iconName ?? type.defaultIconName)
                .font(GentleTypography.headline)
                .foregroundStyle(type.tintColor)
                .frame(width: 20, height: 20)
                .padding(.top, 1)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: GentleSpacing.micro) {
                if let title {
                    Text(LocalizedStringKey(title))
                        .font(GentleTypography.bodyMedium)
                        .foregroundStyle(GentleColor.textPrimary)
                }

                Text(LocalizedStringKey(message))
                    .font(GentleTypography.footnote)
                    .foregroundStyle(GentleColor.textSecondary)
                    .lineSpacing(2)

                if let actionTitle, let onAction {
                    Button {
                        GentleHaptics.selection()
                        onAction()
                    } label: {
                        Text(LocalizedStringKey(actionTitle))
                            .font(GentleTypography.captionSmall)
                            .foregroundStyle(type.tintColor)
                    }
                    .padding(.top, GentleSpacing.xs)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(GentleSpacing.md)
        .background(type.tintColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: GentleCornerRadius.lg, style: .continuous)
                .stroke(
                    colorSchemeContrast == .increased
                        ? type.tintColor.opacity(0.4)
                        : type.tintColor.opacity(0.18),
                    lineWidth: 1
                )
        )
    }
}
