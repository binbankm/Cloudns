import SwiftUI

// MARK: - ApiKeyGuideSheet (Gentle & Comforting Step-by-Step Guide)

struct ApiKeyGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    init() {}

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GentleSheetHeader(
                    title: "Global API Key",
                    subtitle: "How to locate your key",
                    trailingButtonTitle: "Done",
                    onTrailingAction: {
                        dismiss()
                    }
                )

                ScrollView {
                    VStack(spacing: GentleSpacing.lg) {
                        // Security Guarantee Callout
                        GentleCallout(
                            title: "Keychain Protected",
                            message: "Stored exclusively in your local device Keychain. Never relayed through third-party servers.",
                            type: .success,
                            iconName: "lock.shield.fill"
                        )

                        // Step-by-Step Guide Cards
                        VStack(spacing: GentleSpacing.md) {
                            stepRow(
                                stepNumber: "1",
                                title: "Cloudflare Dashboard",
                                description: "Sign in to dash.cloudflare.com.",
                                icon: "safari.fill"
                            )

                            stepRow(
                                stepNumber: "2",
                                title: "Profile → API Tokens",
                                description: "Open your profile and select the API Tokens tab.",
                                icon: "person.crop.circle"
                            )

                            stepRow(
                                stepNumber: "3",
                                title: "Copy Global API Key",
                                description: "Locate Global API Key, select View, verify, and copy.",
                                icon: "key.fill"
                            )
                        }

                        // Open Official Console Link
                        Link(destination: URL(string: "https://dash.cloudflare.com/profile/api-tokens")!) {
                            HStack(spacing: GentleSpacing.xs) {
                                Image(systemName: "arrow.up.right.square")
                                    .font(GentleTypography.bodyMedium)
                                Text("Open Cloudflare Dashboard")
                            }
                            .foregroundStyle(GentleColor.accent)
                        }
                        .gentleSecondaryButton(cornerRadius: GentleCornerRadius.lg, height: 48)
                        .padding(.top, GentleSpacing.xs)
                    }
                    .padding(GentleSpacing.lg)
                }
                .gentleCanvas()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private func stepRow(stepNumber: String, title: String, description: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: GentleSpacing.md) {
            ZStack {
                Circle()
                    .fill(GentleColor.accent.opacity(0.12))
                    .frame(width: GentleSpacing.xxl, height: GentleSpacing.xxl)

                Text(stepNumber)
                    .font(GentleTypography.subheadlineBold)
                    .foregroundStyle(GentleColor.accent)
            }

            VStack(alignment: .leading, spacing: GentleSpacing.xxs) {
                HStack(spacing: GentleSpacing.xs) {
                    Image(systemName: icon)
                        .font(GentleTypography.caption)
                        .foregroundStyle(GentleColor.textSecondary)

                    Text(title)
                        .font(GentleTypography.subheadlineBold)
                        .foregroundStyle(GentleColor.textPrimary)
                }

                Text(description)
                    .font(GentleTypography.footnote)
                    .foregroundStyle(GentleColor.textSecondary)
                    .lineSpacing(GentleSpacing.micro)
            }

            Spacer()
        }
        .gentleCardStyle(cornerRadius: GentleCornerRadius.lg, padding: GentleSpacing.md)
    }
}

#Preview {
    ApiKeyGuideSheet()
}
