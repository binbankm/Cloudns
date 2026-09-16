import SwiftUI

// MARK: - ZonesListView (Phase 3: Domain Management & Gentle Zones Dashboard)

struct ZonesListView: View {
    @StateObject private var viewModel: ZonesListViewModel
    @ObservedObject private var accountManager = AccountManager.shared
    @State private var showAccountSwitcher: Bool = false
    @State private var showAddZoneSheet: Bool = false
    @State private var zoneToDelete: Zone?
    @State private var showDeleteConfirmation: Bool = false

    init(viewModel: ZonesListViewModel = ZonesListViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: GentleSpacing.lg) {
                    // MARK: - Filter & Search Controls

                    searchAndFilterSection

                    // MARK: - ViewState Machine Handling

                    switch viewModel.state {
                    case .idle, .loading:
                        loadingView

                    case .loaded:
                        loadedContent

                    case let .empty(message):
                        GentleEmptyStateView(
                            iconName: "globe.badge.chevron.backward",
                            title: "No Domains",
                            message: message,
                            actionTitle: "Refresh",
                            action: {
                                Task { await viewModel.loadZones() }
                            }
                        )
                        .padding(.top, GentleSpacing.xl)

                    case let .error(message):
                        GentleErrorView(
                            message: message,
                            retryAction: {
                                Task { await viewModel.loadZones() }
                            }
                        )
                        .padding(.top, GentleSpacing.xl)
                    }

                    Spacer(minLength: GentleSpacing.huge)
                }
                .padding(.horizontal, GentleSpacing.lg)
                .padding(.top, GentleSpacing.sm)
            }
            .gentleKeyboardDismissable()
            .gentleCanvas()
            .navigationTitle("Domains")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        GentleHaptics.light()
                        showAddZoneSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(GentleTypography.subheadlineBold)
                            .foregroundStyle(GentleColor.accent)
                            .frame(width: GentleSpacing.xxl, height: GentleSpacing.xxl)
                            .background(GentleColor.cardSurface)
                            .clipShape(Circle())
                            .gentleSubtleShadow()
                    }
                    .transaction { $0.animation = nil }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    accountSwitcherCapsule
                }
            }
            .refreshable {
                await viewModel.refreshZones()
            }
            .task {
                async let syncOfficialName: () = syncOfficialAccountNameIfNeeded()
                if case .idle = viewModel.state {
                    await viewModel.loadZones()
                }
                _ = await syncOfficialName
            }
            .sheet(isPresented: $showAccountSwitcher) {
                AccountSwitcherView()
            }
            .sheet(isPresented: $showAddZoneSheet) {
                AddZoneSheet { newZone in
                    viewModel.addZoneLocally(newZone)
                }
            }
            .confirmationDialog(
                "Delete Domain",
                isPresented: $showDeleteConfirmation,
                presenting: zoneToDelete
            ) { zone in
                Button("Delete \(zone.name)", role: .destructive) {
                    Task {
                        try? await viewModel.deleteZone(id: zone.id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { zone in
                Text("Permanently delete \(zone.name)? DNS routing will stop immediately.")
            }
        }
    }

    // MARK: - Loaded Content

    private var loadedContent: some View {
        VStack(spacing: GentleSpacing.lg) {
            // Health Ring Summary Card
            HealthRingCard(
                healthPercentage: viewModel.healthPercentage,
                activeCount: viewModel.activeZonesCount,
                totalCount: viewModel.totalZonesCount,
                pendingCount: viewModel.pendingZonesCount,
                pausedCount: viewModel.pausedZonesCount
            )

            // Domains List
            if viewModel.filteredZones.isEmpty {
                GentleEmptyStateView(
                    iconName: "magnifyingglass",
                    title: "No Matching Domains",
                    message: "No domains match your search or filter criteria."
                )
                .padding(.top, GentleSpacing.lg)
            } else {
                LazyVStack(spacing: GentleSpacing.md) {
                    ForEach(viewModel.filteredZones) { zone in
                        NavigationLink {
                            ZoneDetailView(zone: zone)
                        } label: {
                            ZoneCardView(
                                zone: zone,
                                onTogglePause: {
                                    Task {
                                        await viewModel.togglePause(for: zone)
                                    }
                                },
                                onRequestDelete: {
                                    zoneToDelete = zone
                                    showDeleteConfirmation = true
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Search and Filter Controls

    private var searchAndFilterSection: some View {
        VStack(spacing: GentleSpacing.sm) {
            // DesignSystem Search Bar
            GentleSearchBar(
                text: $viewModel.searchText,
                placeholder: "Search domains"
            )

            // DesignSystem Sliding Segmented Control
            GentleSegmentedControl(
                items: ZoneStatusFilter.allCases,
                selection: $viewModel.selectedFilter
            )
        }
    }

    // MARK: - Skeletons (Loading State)

    private var loadingView: some View {
        VStack(spacing: GentleSpacing.lg) {
            // Health Ring Card Skeleton
            HStack(spacing: GentleSpacing.lg) {
                Circle()
                    .stroke(GentleColor.cardSurfaceSecondary, lineWidth: GentleSpacing.xs)
                    .frame(width: 76, height: 76)
                    .padding(.leading, GentleSpacing.xs)

                VStack(alignment: .leading, spacing: GentleSpacing.sm) {
                    RoundedRectangle(cornerRadius: GentleCornerRadius.xs, style: .continuous)
                        .fill(GentleColor.cardSurfaceSecondary)
                        .frame(width: 140, height: 16)

                    RoundedRectangle(cornerRadius: GentleCornerRadius.xs, style: .continuous)
                        .fill(GentleColor.cardSurfaceSecondary.opacity(0.7))
                        .frame(width: 180, height: 12)
                }

                Spacer()
            }
            .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: GentleSpacing.lg)
            .gentleShimmer()

            // Zone Card Skeletons (Compact with Avatar)
            LazyVStack(spacing: GentleSpacing.sm) {
                ForEach(0 ..< 4, id: \.self) { _ in
                    HStack(alignment: .center, spacing: GentleSpacing.sm) {
                        RoundedRectangle(cornerRadius: GentleCornerRadius.md, style: .continuous)
                            .fill(GentleColor.cardSurfaceSecondary)
                            .frame(width: 38, height: 38)

                        RoundedRectangle(cornerRadius: GentleCornerRadius.xs, style: .continuous)
                            .fill(GentleColor.cardSurfaceSecondary)
                            .frame(width: 140, height: 18)

                        Spacer()

                        Capsule()
                            .fill(GentleColor.cardSurfaceSecondary)
                            .frame(width: 60, height: 22)
                    }
                    .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: GentleSpacing.md)
                    .gentleShimmer()
                }
            }
        }
    }

    // MARK: - Account Switcher Capsule

    private var accountSwitcherCapsule: some View {
        Button {
            showAccountSwitcher = true
            GentleHaptics.selection()
        } label: {
            if let current = accountManager.currentAccount {
                HStack(spacing: GentleSpacing.xs) {
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
                        .frame(maxWidth: 95)

                    Image(systemName: "chevron.down")
                        .font(GentleTypography.captionSmall)
                        .foregroundStyle(GentleColor.textSecondary)
                }
                .padding(.horizontal, GentleSpacing.sm)
                .padding(.vertical, GentleSpacing.xxs)
                .background(GentleColor.cardSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(GentleColor.cardSurfaceSecondary, lineWidth: 1)
                )
                .gentleSubtleShadow()
            }
        }
        .buttonStyle(.plain)
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    // MARK: - Account Name Synchronization

    private func syncOfficialAccountNameIfNeeded() async {
        guard let current = accountManager.currentAccount else { return }
        let isHex = is32CharHex(current.name)
        let isEmail = current.name.lowercased() == current.email.lowercased()
        guard isHex || isEmail else { return }

        if let accounts = try? await AuthService.shared.getAccounts(),
           let official = accounts.first(where: { !$0.name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty }),
           !is32CharHex(official.name) {
            if official.name != current.name {
                accountManager.updateAccountName(id: current.id, name: official.name)
            }
        }
    }

    private func is32CharHex(_ string: String) -> Bool {
        guard string.count == 32 else { return false }
        return string.allSatisfy(\.isHexDigit)
    }
}

#Preview {
    ZonesListView()
}
