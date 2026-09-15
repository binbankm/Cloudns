import SwiftUI

// MARK: - Design System Gallery / Catalog (Showcase & Verification)

/// Visual showcase of all Gentle Design System tokens and components.
public struct DesignSystemGalleryView: View {
    @State private var sampleText: String = ""
    @State private var sampleSecureText: String = "GlobalApiKey37CharactersExample"
    @State private var sampleSearchQuery: String = ""
    @State private var sampleProxyOn: Bool = true
    @State private var sampleLoading: Bool = false
    @State private var showConfirmDialog: Bool = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GentleSpacing.xl) {
                headerSection
                colorSection
                typographySection
                badgeSection
                calloutSection
                progressSection
                searchSection
                avatarSection
                cardSection
                componentSection
                listRowSection
                buttonSection
                inputSection
                stateSection
                bannerSection
            }
            .padding(.horizontal, GentleSpacing.pageHorizontal)
            .padding(.vertical, GentleSpacing.xl)
        }
        .gentleCanvas()
        .gentleBannerOverlay()
        .gentleConfirmationDialog(
            isPresented: $showConfirmDialog,
            title: "Delete DNS Record",
            message: "This action cannot be undone. Are you sure you want to remove this record from Cloudflare?",
            confirmTitle: "Delete Record",
            confirmRole: .destructive
        ) {
            GentleBannerManager.shared.show(
                type: .success,
                title: "Record Deleted",
                message: "DNS record has been successfully purged."
            )
        }
    }

    // MARK: - Callouts & Notices

    private var calloutSection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.sm) {
            Text(verbatim: "Inline Callouts & Tips")
                .font(GentleTypography.titleSection)
                .foregroundStyle(GentleColor.textPrimary)

            VStack(spacing: GentleSpacing.sm) {
                GentleCallout(
                    title: "Keychain Security Isolation",
                    message: "37-character Global API Key is stored only within the device secure keychain.",
                    type: .info
                )

                GentleCallout(
                    title: "SSL/TLS Universal Mode",
                    message: "Edge certificates are active and enforcing HTTPS redirection.",
                    type: .success
                )

                GentleCallout(
                    title: "DNS Flattening Notice",
                    message: "CNAME records at the root zone are automatically flattened by Cloudflare.",
                    type: .warning
                )
            }
        }
    }

    // MARK: - Progress & Spinners

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.sm) {
            Text(verbatim: "Progress & Activity Indicators")
                .font(GentleTypography.titleSection)
                .foregroundStyle(GentleColor.textPrimary)

            GentleCard {
                VStack(spacing: GentleSpacing.md) {
                    HStack {
                        Text(verbatim: "SSL Deployment Progress")
                            .font(GentleTypography.bodyMedium)
                            .foregroundStyle(GentleColor.textPrimary)
                        Spacer()
                        Text(verbatim: "75%")
                            .font(GentleTypography.metricCard)
                            .foregroundStyle(GentleColor.accent)
                    }

                    GentleProgressBar(value: 0.75, tint: GentleColor.accent)

                    GentleDivider()

                    HStack(spacing: GentleSpacing.lg) {
                        Text(verbatim: "Gentle Spinner Styles:")
                            .font(GentleTypography.footnote)
                            .foregroundStyle(GentleColor.textSecondary)

                        GentleSpinner(tint: GentleColor.accent, size: 18)
                        GentleSpinner(tint: GentleColor.sageGreen, size: 18)
                        GentleSpinner(tint: GentleColor.statusDanger, size: 18)
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Search Section

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.sm) {
            Text(verbatim: "Search Bar")
                .font(GentleTypography.titleSection)
                .foregroundStyle(GentleColor.textPrimary)

            GentleSearchBar(
                text: $sampleSearchQuery,
                placeholder: "Search domains or records"
            )
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.sm) {
            Text(verbatim: "Account Avatars")
                .font(GentleTypography.titleSection)
                .foregroundStyle(GentleColor.textPrimary)

            GentleCard {
                HStack(spacing: GentleSpacing.md) {
                    GentleAvatar(name: "Production Master", size: .small, isActive: true)
                    GentleAvatar(name: "Dev Workspace", email: "dev@cloudflare.com", size: .medium, isActive: true)
                    GentleAvatar(name: "Acme Corp", size: .large, isActive: false)
                    GentleAvatar(name: "Cloudflare Inc", size: .xlarge, isActive: true)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Specialized Components

    private var componentSection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.sm) {
            Text(verbatim: "Specialized Components")
                .font(GentleTypography.titleSection)
                .foregroundStyle(GentleColor.textPrimary)

            GentleCard {
                VStack(spacing: GentleSpacing.md) {
                    HStack {
                        Text(verbatim: "Cloudflare Proxy Status")
                            .font(GentleTypography.bodyMedium)
                            .foregroundStyle(GentleColor.textPrimary)
                        Spacer()
                        Toggle(isOn: $sampleProxyOn) {
                            EmptyView()
                        }
                        .toggleStyle(.gentleProxy)
                    }

                    GentleDivider()

                    GentleSegmentedControl(
                        items: ["ALL", "A", "CNAME", "TXT", "MX"],
                        selection: .constant("ALL")
                    )

                    GentleDivider()

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(verbatim: "Zone Health Overview")
                                .font(GentleTypography.cardTitle)
                                .foregroundStyle(GentleColor.textPrimary)
                            Text(verbatim: "Active DNS & SSL routing")
                                .font(GentleTypography.caption)
                                .foregroundStyle(GentleColor.textSecondary)
                        }
                        Spacer()
                        GentleRingView(progress: 0.94, diameter: 70)
                    }
                }
            }
        }
    }

    // MARK: - List Rows & Sections

    private var listRowSection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.sm) {
            Text(verbatim: "Grouped Rows & Insets")
                .font(GentleTypography.titleSection)
                .foregroundStyle(GentleColor.textPrimary)

            VStack(spacing: 0) {
                GentleListRow(
                    title: "Audit Logs",
                    subtitle: "View recent Cloudflare API actions",
                    showDivider: true,
                    showChevron: true,
                    action: { GentleHaptics.selection() },
                    leading: {
                        GentleIconTile(systemName: "list.bullet.rectangle", tint: GentleColor.accent)
                    }
                )

                GentleListRow(
                    title: "Security Level",
                    value: "Medium",
                    showDivider: true,
                    showChevron: true,
                    action: { GentleHaptics.selection() },
                    leading: {
                        GentleIconTile(systemName: "shield.lefthalf.filled", tint: GentleColor.sageGreen)
                    }
                )

                GentleListRow(
                    title: "Development Mode",
                    subtitle: "Bypass cache for 3 hours",
                    showDivider: false,
                    leading: {
                        GentleIconTile(systemName: "hammer.fill", tint: GentleColor.apricotGold)
                    },
                    trailing: {
                        Toggle(isOn: $sampleProxyOn) {
                            EmptyView()
                        }
                        .labelsHidden()
                        .gentleToggle()
                    }
                )
            }
            .gentleCard()
        }
    }

    // MARK: - Banners

    private var bannerSection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.sm) {
            Text(verbatim: "Gentle Notification Banners")
                .font(GentleTypography.titleSection)
                .foregroundStyle(GentleColor.textPrimary)

            VStack(spacing: GentleSpacing.sm) {
                Button {
                    GentleBannerManager.shared.show(
                        type: .success,
                        title: "Account Switched",
                        message: "Active account switched seamlessly to Personal Site."
                    )
                } label: {
                    Text(verbatim: "Trigger: Success Banner (Account Switched)")
                }
                .gentleSecondaryButton(height: 44)

                Button {
                    GentleBannerManager.shared.showOffline()
                } label: {
                    Text(verbatim: "Trigger: Offline Banner (AGENTS.md Guideline)")
                }
                .gentleSecondaryButton(height: 44)

                Button {
                    GentleBannerManager.shared.show(
                        type: .warning,
                        title: "Record Notice",
                        message: "This DNS record has been proxied via CNAME flattening."
                    )
                } label: {
                    Text(verbatim: "Trigger: Warning Banner (DNS Flattening)")
                }
                .gentleSecondaryButton(height: 44)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.xs) {
            Text(verbatim: "Gentle Design System")
                .font(GentleTypography.hero)
                .foregroundStyle(GentleColor.textPrimary)

            Text(verbatim: "Ultra-Gentle & Cozy HIG Foundation")
                .font(GentleTypography.body)
                .foregroundStyle(GentleColor.textSecondary)
        }
    }

    // MARK: - Colors

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.sm) {
            Text(verbatim: "Colors & Badges")
                .font(GentleTypography.titleSection)
                .foregroundStyle(GentleColor.textPrimary)

            GentleCard {
                VStack(spacing: GentleSpacing.sm) {
                    colorRow(name: "Background", color: GentleColor.background)
                    colorRow(name: "Card Surface", color: GentleColor.cardSurface)
                    colorRow(name: "Warm Accent", color: GentleColor.accent)
                    colorRow(name: "Status Active", color: GentleColor.statusActive)
                    colorRow(name: "Status Proxied", color: GentleColor.statusProxied)
                    colorRow(name: "Status Danger", color: GentleColor.statusDanger)
                }
            }
        }
    }

    private func colorRow(name: String, color: Color) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: GentleCornerRadius.sm, style: .continuous)
                .fill(color)
                .frame(width: 32, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: GentleCornerRadius.sm, style: .continuous)
                        .stroke(GentleColor.border, lineWidth: 1)
                )

            Text(name)
                .font(GentleTypography.bodyMedium)
                .foregroundStyle(GentleColor.textPrimary)

            Spacer()
        }
    }

    // MARK: - Typography

    private var typographySection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.sm) {
            Text(verbatim: "Typography (SF Pro Rounded)")
                .font(GentleTypography.titleSection)
                .foregroundStyle(GentleColor.textPrimary)

            GentleCard {
                VStack(alignment: .leading, spacing: GentleSpacing.sm) {
                    Text(verbatim: "Title Large")
                        .font(GentleTypography.titleLarge)
                        .foregroundStyle(GentleColor.textPrimary)

                    Text(verbatim: "Card Headline Title")
                        .font(GentleTypography.cardTitle)
                        .foregroundStyle(GentleColor.textPrimary)

                    Text(verbatim: "Standard Body Text")
                        .font(GentleTypography.body)
                        .foregroundStyle(GentleColor.textSecondary)

                    HStack {
                        Text(verbatim: "Monospaced Metric:")
                            .font(GentleTypography.caption)
                            .foregroundStyle(GentleColor.textSecondary)
                        Text(verbatim: "1,248,392 reqs")
                            .font(GentleTypography.metricMedium)
                            .foregroundStyle(GentleColor.accent)
                    }
                }
            }
        }
    }

    // MARK: - Badges

    private var badgeSection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.sm) {
            Text(verbatim: "Semantic Badges")
                .font(GentleTypography.titleSection)
                .foregroundStyle(GentleColor.textPrimary)

            GentleCard {
                HStack(spacing: GentleSpacing.xs) {
                    GentleBadge("Active", iconName: "checkmark", type: .active)
                    GentleBadge("Proxied", iconName: "cloud.fill", type: .proxied)
                    GentleBadge("Warning", iconName: "clock.fill", type: .warning)
                    GentleBadge("Delete", iconName: "trash.fill", type: .danger)
                }
            }
        }
    }

    // MARK: - Cards

    private var cardSection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.sm) {
            Text(verbatim: "Card Variants")
                .font(GentleTypography.titleSection)
                .foregroundStyle(GentleColor.textPrimary)

            VStack(spacing: GentleSpacing.cardSpacing) {
                GentleCard(variant: .elevated) {
                    HStack {
                        Text(verbatim: "Elevated Floating Card")
                            .font(GentleTypography.bodyMedium)
                            .foregroundStyle(GentleColor.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(GentleColor.textSecondary)
                    }
                }

                GentleCard(variant: .highlighted) {
                    HStack {
                        Text(verbatim: "Highlighted Card (Amber Glow)")
                            .font(GentleTypography.bodyMedium)
                            .foregroundStyle(GentleColor.textPrimary)
                        Spacer()
                    }
                }

                Button {
                    GentleHaptics.selection()
                } label: {
                    HStack {
                        Text(verbatim: "Interactive Tap Card (Spring Scale)")
                            .font(GentleTypography.bodyMedium)
                            .foregroundStyle(GentleColor.textPrimary)
                        Spacer()
                        Image(systemName: "hand.tap.fill")
                            .foregroundStyle(GentleColor.accent)
                    }
                }
                .buttonStyle(GentleCardButtonStyle())
            }
        }
    }

    // MARK: - Buttons & Actions

    private var buttonSection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.sm) {
            Text(verbatim: "Buttons & Confirmation")
                .font(GentleTypography.titleSection)
                .foregroundStyle(GentleColor.textPrimary)

            VStack(spacing: GentleSpacing.sm) {
                Button {} label: {
                    Text(verbatim: "Primary Amber Button")
                }
                .gentlePrimaryButton()

                GentleLoadingButton(
                    "Simulate Async Action",
                    isLoading: sampleLoading,
                    iconName: "bolt.fill"
                ) {
                    sampleLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        sampleLoading = false
                        GentleHaptics.success()
                    }
                }

                Button {} label: {
                    Text(verbatim: "Secondary Surface Button")
                }
                .gentleSecondaryButton()

                Button {
                    showConfirmDialog = true
                } label: {
                    Text(verbatim: "Trigger Confirmation Dialog (Destructive)")
                }
                .gentleDestructiveButton()
            }
        }
    }

    // MARK: - Inputs

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.sm) {
            Text(verbatim: "Input Fields")
                .font(GentleTypography.titleSection)
                .foregroundStyle(GentleColor.textPrimary)

            VStack(spacing: GentleSpacing.sm) {
                GentleTextField(
                    "Cloudflare Account Email",
                    text: $sampleText,
                    leadingIcon: "envelope.fill"
                )

                GentleTextField(
                    "37-character Global API Key",
                    text: $sampleSecureText,
                    leadingIcon: "key.fill",
                    isSecure: true,
                    isMonospaced: true
                )
            }
        }
    }

    // MARK: - States

    private var stateSection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.sm) {
            Text(verbatim: "State Views & Shimmer")
                .font(GentleTypography.titleSection)
                .foregroundStyle(GentleColor.textPrimary)

            VStack(spacing: GentleSpacing.sm) {
                GentleCard {
                    VStack(alignment: .leading, spacing: GentleSpacing.xs) {
                        RoundedRectangle(cornerRadius: GentleCornerRadius.xs, style: .continuous)
                            .fill(GentleColor.textSecondary.opacity(0.12))
                            .frame(width: 140, height: 16)
                            .gentleShimmer()

                        RoundedRectangle(cornerRadius: GentleCornerRadius.xs, style: .continuous)
                            .fill(GentleColor.textSecondary.opacity(0.08))
                            .frame(maxWidth: .infinity)
                            .frame(height: 12)
                            .gentleShimmer()
                    }
                }

                GentleEmptyStateView(
                    iconName: "globe.asia.australia.fill",
                    title: "No Domains Yet",
                    message: "No domains found under this account · Tap below to bind",
                    actionTitle: "Add New Domain"
                ) {}
                    .gentleCardStyle()
            }
        }
    }
}

#Preview {
    DesignSystemGalleryView()
}
