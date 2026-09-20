import SwiftUI

// MARK: - PlanUpgradeSheetView

// Apple HIG Compliant Plan Tier Entitlements and Upgrade Pathway Sheet (iOS 16.0+)

public struct PlanUpgradeSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject private var themeManager = ThemeManager.shared

    public let featureName: LocalizedStringKey
    public let currentTier: PlanTier?
    public let requiredTier: PlanTier
    public let zoneName: String?

    public init(featureName: LocalizedStringKey, currentTier: PlanTier? = nil, requiredTier: PlanTier, zoneName: String? = nil) {
        self.featureName = featureName
        self.currentTier = currentTier
        self.requiredTier = requiredTier
        self.zoneName = zoneName
    }

    private var accentColor: Color {
        themeManager.accentColor
    }

    private var tierColor: Color {
        PlanBadgeView.color(for: requiredTier)
    }

    private var secondaryTierColor: Color {
        switch requiredTier {
        case .free:
            .gray
        case .pro:
            .indigo
        case .business:
            .indigo
        case .enterprise:
            .orange
        case .paid, .addOn:
            .red
        }
    }

    private var iconName: String {
        switch requiredTier {
        case .free: "globe"
        case .pro: "sparkles"
        case .business: "building.2.fill"
        case .enterprise: "crown.fill"
        case .paid: "bolt.fill"
        case .addOn: "puzzlepiece.extension.fill"
        }
    }

    public var body: some View {
        NavigationStack {
            List {
                // MARK: - 1. Feature & Tier Notice
                Section {
                    VStack(spacing: 14) {
                        HeroHeaderEmblemView(
                            icon: iconName,
                            primaryColor: tierColor,
                            secondaryColor: secondaryTierColor,
                            size: 56
                        )
                        .padding(.top, 6)

                        VStack(spacing: 6) {
                            HStack(spacing: 8) {
                                Text(featureName)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                PlanBadgeView(required: requiredTier, current: .free)
                            }

                            Text("This feature is part of Cloudflare \(requiredTier.displayName) and is locked for your current plan.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                // MARK: - 2. Domain Scope (if applicable)
                if let zoneName, !zoneName.isEmpty {
                    Section {
                        LabeledContent {
                            Text(zoneName)
                                .font(.subheadline.monospaced())
                                .foregroundStyle(.secondary)
                        } label: {
                            Label("Zone Name", systemImage: "globe")
                        }
                    }
                }

                // MARK: - 3. Upgrade Action
                Section {
                    Button {
                        HapticManager.impact(.medium)
                        openDashboardUpgrade()
                    } label: {
                        HStack(spacing: 8) {
                            Spacer()
                            Text("Upgrade on Cloudflare")
                                .font(.body.weight(.semibold))
                            Image(systemName: "arrow.up.forward.app")
                                .font(.footnote.weight(.semibold))
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(tierColor)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } footer: {
                    Text("Plan upgrades are securely handled via your Cloudflare Dashboard.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Upgrade Plan")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.height(380), .medium])
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        HapticManager.selection()
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(accentColor)
                }
            }
        }
    }

    // MARK: - Actions

    private func openDashboardUpgrade() {
        let urlString: String
        if requiredTier == .paid {
            urlString = "https://dash.cloudflare.com/?to=/:account/workers/plans"
        } else if let zoneName, !zoneName.isEmpty {
            urlString = "https://dash.cloudflare.com/?to=/:account/\(zoneName)/plans"
        } else {
            urlString = "https://dash.cloudflare.com"
        }
        if let url = URL(string: urlString) {
            openURL(url)
        }
    }
}

// MARK: - Preview

#Preview {
    PlanUpgradeSheetView(
        featureName: "WAF Managed Rules",
        requiredTier: .pro,
        zoneName: "example.com"
    )
}
