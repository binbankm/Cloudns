import SwiftUI

// MARK: - Root Content Container (AGENTS.md Multi-Account & Auth Flow)

struct ContentView: View {
    @ObservedObject private var accountManager = AccountManager.shared
    @State private var showAccountSwitcher: Bool = false

    var body: some View {
        Group {
            if let current = accountManager.currentAccount {
                authenticatedView(current: current)
            } else {
                LoginView()
            }
        }
        .animation(GentleAnimation.spring, value: accountManager.currentAccount?.id)
        .gentleBannerOverlay()
    }

    // MARK: - Authenticated View Container

    private func authenticatedView(current: CloudflareAccount) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: GentleSpacing.xl) {
                    // MARK: - Warm Hero Card

                    VStack(alignment: .leading, spacing: GentleSpacing.md) {
                        HStack(spacing: GentleSpacing.md) {
                            GentleAvatar(
                                name: current.name,
                                email: current.email,
                                size: .large,
                                isActive: true
                            )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(current.name)
                                    .font(GentleTypography.titleSection)
                                    .foregroundStyle(GentleColor.textPrimary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)

                                Text(current.email)
                                    .font(GentleTypography.subheadline)
                                    .foregroundStyle(GentleColor.textSecondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }

                            Spacer()

                            GentleBadge("Active", iconName: "checkmark", type: .active)
                        }

                        GentleDivider()

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: GentleSpacing.sm) {
                                GentleBadge("Global Key", iconName: "key.fill", type: .custom(color: GentleColor.accent))
                                GentleBadge("Keychain Isolated", iconName: "lock.shield.fill", type: .custom(color: GentleColor.statusActive))
                                GentleBadge("iOS 16+", iconName: "applelogo", type: .custom(color: GentleColor.textSecondary))
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: GentleSpacing.sm) {
                                    GentleBadge("Global Key", iconName: "key.fill", type: .custom(color: GentleColor.accent))
                                    GentleBadge("Keychain Isolated", iconName: "lock.shield.fill", type: .custom(color: GentleColor.statusActive))
                                    GentleBadge("iOS 16+", iconName: "applelogo", type: .custom(color: GentleColor.textSecondary))
                                }
                            }
                        }
                    }
                    .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: GentleSpacing.lg)
                    .padding(.top, GentleSpacing.sm)

                    // MARK: - Next Phase Preview

                    VStack(alignment: .leading, spacing: GentleSpacing.md) {
                        HStack {
                            Text("Infrastructure Ready")
                                .font(GentleTypography.subheadlineBold)
                                .foregroundStyle(GentleColor.textPrimary)

                            Spacer()

                            Text("Phase 2 Complete")
                                .font(GentleTypography.caption)
                                .foregroundStyle(GentleColor.accent)
                        }

                        Text("Authentication and hardware-isolated multi-account storage are fully operational. Tap the account capsule in the navigation bar to seamlessly switch accounts or add new credentials.")
                            .font(GentleTypography.footnote)
                            .foregroundStyle(GentleColor.textSecondary)
                            .lineSpacing(3)
                    }
                    .gentleCardStyle(cornerRadius: GentleCornerRadius.xl, padding: GentleSpacing.lg)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, GentleSpacing.lg)
            }
            .gentleCanvas()
            .navigationTitle("Cloudns")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAccountSwitcher = true
                        GentleHaptics.selection()
                    } label: {
                        HStack(spacing: 6) {
                            GentleAvatar(
                                name: current.name,
                                email: current.email,
                                size: .small,
                                isActive: true
                            )

                            Text(current.name)
                                .font(GentleTypography.subheadline)
                                .foregroundStyle(GentleColor.textPrimary)
                                .lineLimit(1)
                                .frame(maxWidth: 140)

                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(GentleColor.textSecondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(GentleColor.cardSurface)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    }
                }
            }
            .sheet(isPresented: $showAccountSwitcher) {
                AccountSwitcherView()
            }
            .task {
                await syncOfficialAccountNameIfNeeded(for: current)
            }
        }
    }

    // MARK: - Account Name Synchronization

    private func syncOfficialAccountNameIfNeeded(for account: CloudflareAccount) async {
        let isHex = is32CharHex(account.name)
        let isEmail = account.name.lowercased() == account.email.lowercased()
        guard isHex || isEmail else { return }

        // Fetch official accounts from Cloudflare API (GET /client/v4/accounts)
        if let accounts = try? await AuthService.shared.getAccounts(),
           let official = accounts.first(where: { !$0.name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty }),
           !is32CharHex(official.name) {
            accountManager.updateAccountName(id: account.id, name: official.name)
        } else if let (zones, _) = try? await ZoneService.shared.getZones(page: 1, perPage: 1),
                  let zoneAccountName = zones.first?.account?.name,
                  !zoneAccountName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty,
                  !is32CharHex(zoneAccountName) {
            accountManager.updateAccountName(id: account.id, name: zoneAccountName)
        }
    }

    private func is32CharHex(_ string: String) -> Bool {
        guard string.count == 32 else { return false }
        return string.allSatisfy { $0.isHexDigit }
    }
}

#Preview {
    ContentView()
}
