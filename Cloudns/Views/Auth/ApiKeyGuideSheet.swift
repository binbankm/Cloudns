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
                        HStack(alignment: .top, spacing: GentleSpacing.md) {
                            Image(systemName: "lock.shield.fill")
                                .font(GentleTypography.cardTitle)
                                .foregroundStyle(GentleColor.statusActive)
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Keychain Protected")
                                    .font(GentleTypography.subheadlineBold)
                                    .foregroundStyle(GentleColor.textPrimary)

                                Text("Stored exclusively in your local device Keychain. Never relayed through third-party servers.")
                                    .font(GentleTypography.caption)
                                    .foregroundStyle(GentleColor.textSecondary)
                                    .lineSpacing(2)
                            }
                        }
                        .padding(GentleSpacing.md)
                        .background(GentleColor.statusActive.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.lg, style: .continuous))

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
                                    .font(GentleTypography.bodyMedium)
                            }
                            .foregroundStyle(GentleColor.accent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(GentleColor.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.lg, style: .continuous))
                        }
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
                    .frame(width: 32, height: 32)

                Text(stepNumber)
                    .font(GentleTypography.subheadlineBold)
                    .foregroundStyle(GentleColor.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
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
                    .lineSpacing(2)
            }

            Spacer()
        }
        .gentleCardStyle(cornerRadius: GentleCornerRadius.lg, padding: GentleSpacing.md)
    }
}

#Preview {
    ApiKeyGuideSheet()
}
