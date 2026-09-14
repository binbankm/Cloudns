import SwiftUI

// MARK: - Gentle Error View (AGENTS.md 对齐)

/// Reusable humane error state view with actionable retry guidance.
public struct GentleErrorView: View {
    public let message: String
    public var retryAction: (() -> Void)?

    public init(
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.message = message
        self.retryAction = retryAction
    }

    public var body: some View {
        VStack(spacing: GentleSpacing.lg) {
            ZStack {
                Circle()
                    .fill(GentleColor.statusDanger.opacity(0.12))
                    .frame(width: 72, height: 72)

                Image(systemName: "wifi.exclamationmark")
                    .font(GentleTypography.largeTitle)
                    .foregroundStyle(GentleColor.statusDanger)
                    .accessibilityHidden(true)
            }

            VStack(spacing: GentleSpacing.xs) {
                Text("Something Went Wrong")
                    .font(GentleTypography.titleSection)
                    .foregroundStyle(GentleColor.textPrimary)

                Text(LocalizedStringKey(message))
                    .font(GentleTypography.body)
                    .foregroundStyle(GentleColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, GentleSpacing.xl)
            }

            if let retryAction {
                Button {
                    GentleHaptics.light()
                    retryAction()
                } label: {
                    HStack(spacing: GentleSpacing.xs) {
                        Image(systemName: "arrow.clockwise")
                            .font(GentleTypography.callout.weight(.semibold))
                        Text("Tap to Retry")
                    }
                    .padding(.horizontal, GentleSpacing.lg)
                }
                .gentleSecondaryButton(height: 44)
                .frame(maxWidth: 180)
                .padding(.top, GentleSpacing.xs)
            }
        }
        .padding(GentleSpacing.xxl)
        .frame(maxWidth: .infinity)
    }
}
