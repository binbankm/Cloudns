import SwiftUI

// MARK: - Gentle Sheet Header (Standard Half-Sheet Header)

/// Standardized half-sheet navigation header with drag indicator and action buttons.
public struct GentleSheetHeader: View {
    public let title: String
    public var subtitle: String?
    public var leadingButtonTitle: String?
    public var trailingButtonTitle: String?
    public var onLeadingAction: (() -> Void)?
    public var onTrailingAction: (() -> Void)?

    public init(
        title: String,
        subtitle: String? = nil,
        leadingButtonTitle: String? = nil,
        trailingButtonTitle: String? = "Done",
        onLeadingAction: (() -> Void)? = nil,
        onTrailingAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingButtonTitle = leadingButtonTitle
        self.trailingButtonTitle = trailingButtonTitle
        self.onLeadingAction = onLeadingAction
        self.onTrailingAction = onTrailingAction
    }

    public var body: some View {
        VStack(spacing: GentleSpacing.sm) {
            // Drag grabber bar
            Capsule()
                .fill(GentleColor.textSecondary.opacity(0.25))
                .frame(width: 36, height: 5)
                .padding(.top, GentleSpacing.xs)

            HStack {
                if let leadingButtonTitle, let onLeadingAction {
                    Button {
                        GentleHaptics.soft()
                        onLeadingAction()
                    } label: {
                        Text(LocalizedStringKey(leadingButtonTitle))
                            .font(GentleTypography.body)
                            .foregroundStyle(GentleColor.textSecondary)
                    }
                } else {
                    Spacer().frame(width: 44)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(LocalizedStringKey(title))
                        .font(GentleTypography.cardTitle)
                        .foregroundStyle(GentleColor.textPrimary)

                    if let subtitle {
                        Text(LocalizedStringKey(subtitle))
                            .font(GentleTypography.caption)
                            .foregroundStyle(GentleColor.textSecondary)
                    }
                }

                Spacer()

                if let trailingButtonTitle, let onTrailingAction {
                    Button {
                        GentleHaptics.selection()
                        onTrailingAction()
                    } label: {
                        Text(LocalizedStringKey(trailingButtonTitle))
                            .font(GentleTypography.bodyMedium)
                            .foregroundStyle(GentleColor.accent)
                    }
                } else {
                    Spacer().frame(width: 44)
                }
            }
            .padding(.horizontal, GentleSpacing.md)
            .padding(.bottom, GentleSpacing.xs)

            GentleDivider()
        }
        .background(GentleColor.cardSurface)
    }
}
