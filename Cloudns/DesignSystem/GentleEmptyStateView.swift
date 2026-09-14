import SwiftUI

// MARK: - Gentle Empty State View (AGENTS.md 对齐)

/// Reusable comforting empty state view with gentle SF Symbol, microcopy, and action button.
public struct GentleEmptyStateView: View {
    public let iconName: String
    public let title: String
    public let message: String
    public var actionTitle: String?
    public var action: (() -> Void)?

    public init(
        iconName: String = "tray.fill",
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: GentleSpacing.lg) {
            ZStack {
                Circle()
                    .fill(GentleColor.accent.opacity(0.1))
                    .frame(width: 76, height: 76)

                Image(systemName: iconName)
                    .font(GentleTypography.largeTitle)
                    .foregroundStyle(GentleColor.accent)
                    .accessibilityHidden(true)
            }

            VStack(spacing: GentleSpacing.xs) {
                Text(LocalizedStringKey(title))
                    .font(GentleTypography.titleSection)
                    .foregroundStyle(GentleColor.textPrimary)

                Text(LocalizedStringKey(message))
                    .font(GentleTypography.body)
                    .foregroundStyle(GentleColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, GentleSpacing.xl)
            }

            if let actionTitle, let action {
                Button {
                    GentleHaptics.selection()
                    action()
                } label: {
                    Text(LocalizedStringKey(actionTitle))
                        .padding(.horizontal, GentleSpacing.lg)
                }
                .gentleSecondaryButton(height: 44)
                .frame(maxWidth: 220)
                .padding(.top, GentleSpacing.xs)
            }
        }
        .padding(GentleSpacing.xxl)
        .frame(maxWidth: .infinity)
    }
}
