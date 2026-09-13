import Combine
import SwiftUI

// MARK: - DashboardView

// Native Apple HIG Bento Grid, Swift Charts & Live Infrastructure Fleet Metrics

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @ObservedObject private var accountManager = AccountManager.shared
    @State private var showingAccountSheet = false
    @State private var showingAddZone = false
    @ObservedObject private var themeManager = ThemeManager.shared

    private var accentColor: Color {
        themeManager.accentColor
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // 1. Hero Account Identity Card
                        heroHeaderView

                        // 2. Fleet Metrics Overview Grid (2x2)
                        resourcesOverviewGridView

                        // 3. Interactive Zone Analytics (Swift Charts)
                        DashboardZoneTrafficChartView(viewModel: viewModel)

                        // 4. Quick Diagnostics & Operations Deck
                        quickCommandDeckView

                        // 5. Recent Active Domains Section
                        activeZonesSectionView
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    await viewModel.fetchDashboard(isRefresh: true)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.selection()
                        showingAccountSheet = true
                    } label: {
                        AccountAvatarView(identifier: accountManager.activeEmail, size: 34)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Switch Cloudflare Account")
                }
            }
            .sheet(isPresented: $showingAccountSheet) {
                AccountsView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingAddZone) {
                AddZoneView()
            }
            .onReceive(NotificationCenter.default.publisher(for: .accountSwitched)) { _ in
                viewModel.resetState()
                Task { await viewModel.fetchDashboard(isRefresh: true) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .localCachePurged)) { _ in
                viewModel.resetState()
                Task { await viewModel.fetchDashboard(isRefresh: true) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .appWillEnterForeground)) { _ in
                if viewModel.isStale {
                    Task { await viewModel.fetchDashboard(isRefresh: true) }
                }
            }
            .onAppear {
                viewModel.refreshRecentZones()
            }
            .task {
                await viewModel.fetchDashboard(isRefresh: false)
            }
        }
    }

    // MARK: - 1. Hero Header View

    private var heroHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Row: Greeting & Identity
            VStack(alignment: .leading, spacing: 3) {
                let greeting = greetingConfig
                HStack(spacing: 4) {
                    Image(systemName: greeting.icon)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(greeting.color)

                    Text(greeting.text)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Text(viewModel.selectedAccount?.name ?? (accountManager.activeEmail.isEmpty ? String(localized: "Cloudflare Account") : accountManager.activeEmail))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if !accountManager.activeEmail.isEmpty, viewModel.selectedAccount?.name != accountManager.activeEmail {
                    Text(accountManager.activeEmail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Divider()
                .opacity(0.6)

            // Bottom Meta Bar: Account ID Capsule & Architecture Level
            HStack(spacing: 8) {
                if let accountId = viewModel.selectedAccount?.id, !accountId.isEmpty {
                    Button {
                        copyToClipboard(accountId, toast: "Account ID Copied")
                    } label: {
                        HStack(spacing: 4) {
                            Text("ID")
                                .font(.caption2.weight(.bold).monospaced())
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(accentColor.opacity(0.18))
                                .foregroundStyle(accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                            Text(accountId.prefix(8) + "..." + accountId.suffix(4))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)

                            Image(systemName: "doc.on.doc")
                                .font(.caption2)
                                .foregroundStyle(.secondary.opacity(0.8))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Account ID: \(accountId), tap to copy")
                }

                Spacer(minLength: 4)

                HStack(spacing: 4) {
                    Image(systemName: "shield.checkerboard")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.blue)

                    Text("Zero Trust Edge")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.08))
                .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }

    private var greetingConfig: (text: LocalizedStringKey, icon: String, color: Color) {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5 ..< 12:
            return ("Good Morning", "sun.max.fill", .orange)
        case 12 ..< 18:
            return ("Good Afternoon", "sun.haze.fill", .orange)
        default:
            return ("Good Evening", "moon.stars.fill", .indigo)
        }
    }

    // MARK: - 2. Fleet Metrics Overview Cards Grid (2x2)

    private var resourcesOverviewGridView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 155, maximum: 240), spacing: 12)], spacing: 12) {
            NavigationLink {
                ZonesListView(embeddedInNavigation: true)
            } label: {
                DashboardMetricCardView(
                    icon: "globe",
                    iconColor: .blue,
                    title: "Active Domains",
                    value: viewModel.hasFetchedData ? "\(viewModel.activeZonesCount)" : "-",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.zones.count) Total Domains" : "Loading…",
                    badge: "Domains"
                )
            }
            .buttonStyle(.plain)
            .hoverEffect(.lift)

            NavigationLink {
                DeveloperHubView(embeddedInNavigation: true)
            } label: {
                DashboardMetricCardView(
                    icon: "bolt.fill",
                    iconColor: .orange,
                    title: "Workers & Pages",
                    value: viewModel.hasFetchedData ? "\(viewModel.workers.count + viewModel.pages.count)" : "-",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.workers.count) Workers · \(viewModel.pages.count) Pages" : "Loading…",
                    badge: "Compute"
                )
            }
            .buttonStyle(.plain)
            .hoverEffect(.lift)

            NavigationLink {
                if let accId = viewModel.selectedAccount?.id, !accId.isEmpty {
                    KVBrowserView(accountId: accId)
                } else {
                    KVBrowserView(accountId: "current")
                }
            } label: {
                DashboardMetricCardView(
                    icon: "cylinder.split.1x2.fill",
                    iconColor: .purple,
                    title: "Storage & Databases",
                    value: viewModel.hasFetchedData ? "\(viewModel.totalStorageCount)" : "-",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.kvCount) KV · \(viewModel.r2Count) R2 · \(viewModel.d1Count) D1" : "Loading…",
                    badge: "Storage"
                )
            }
            .buttonStyle(.plain)
            .hoverEffect(.lift)

            NavigationLink {
                if let accId = viewModel.selectedAccount?.id, !accId.isEmpty {
                    TunnelsListView(accountId: accId)
                } else {
                    TunnelsListView(accountId: "current")
                }
            } label: {
                DashboardMetricCardView(
                    icon: "shield.righthalf.filled",
                    iconColor: .green,
                    title: "Zero Trust Tunnels",
                    value: viewModel.hasFetchedData ? "\(viewModel.tunnels.count)" : "-",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.healthyTunnelsCount) Healthy" : "Loading…",
                    badge: "Tunnel"
                )
            }
            .buttonStyle(.plain)
            .hoverEffect(.lift)
        }
    }

    // MARK: - 3. Quick Operations Deck (Grid)

    private var quickCommandDeckView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Quick Diagnostics & Tools")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                NavigationLink(destination: NetworkToolsView(embeddedInNavigation: true)) {
                    HStack(spacing: 3) {
                        Text("All Tools")
                        Image(systemName: "chevron.forward")
                            .font(.caption2.weight(.bold))
                    }
                    .font(.subheadline)
                    .foregroundStyle(accentColor)
                }
            }
            .padding(.horizontal, 2)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 14) {
                Button {
                    HapticManager.selection()
                    showingAddZone = true
                } label: {
                    QuickDeckButton(icon: "plus.circle.fill", color: accentColor, title: "Add Domain")
                }
                .buttonStyle(.plain)

                NavigationLink(destination: DNSDigToolView()) {
                    QuickDeckButton(icon: "arrow.triangle.2.circlepath.circle.fill", color: .blue, title: "DNS Dig")
                }
                .buttonStyle(.plain)

                NavigationLink(destination: CFTraceToolView()) {
                    QuickDeckButton(icon: "antenna.radiowaves.left.and.right", color: .purple, title: "Edge Trace")
                }
                .buttonStyle(.plain)

                NavigationLink(destination: CertInspectToolView()) {
                    QuickDeckButton(icon: "lock.shield.fill", color: .cyan, title: "SSL Check")
                }
                .buttonStyle(.plain)

                NavigationLink(destination: IPLookupToolView()) {
                    QuickDeckButton(icon: "network.badge.shield.half.filled", color: .indigo, title: "IP / ASN")
                }
                .buttonStyle(.plain)

                NavigationLink(destination: WhoisToolView()) {
                    QuickDeckButton(icon: "magnifyingglass", color: .teal, title: "WHOIS")
                }
                .buttonStyle(.plain)

                NavigationLink(destination: EdgeLatencyTestView()) {
                    QuickDeckButton(icon: "speedometer", color: .orange, title: "Latency Test")
                }
                .buttonStyle(.plain)

                NavigationLink(destination: CIDRCalculatorView()) {
                    QuickDeckButton(icon: "rectangle.split.3x3.fill", color: .green, title: "CIDR Calc")
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
        }
    }

    // MARK: - 4. Recent Domains Section

    private var activeZonesSectionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Domains")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                NavigationLink(destination: ZonesListView(embeddedInNavigation: true)) {
                    HStack(spacing: 3) {
                        if viewModel.hasFetchedData {
                            Text("See All (\(viewModel.zones.count))")
                        } else {
                            Text("See All")
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                    }
                    .font(.subheadline)
                    .foregroundStyle(accentColor)
                }
            }
            .padding(.horizontal, 2)

            if !viewModel.hasFetchedData {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 32)
                    Spacer()
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else if viewModel.zones.isEmpty {
                VStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .shadow(color: accentColor.opacity(0.25), radius: 8, x: 0, y: 4)

                        Image(systemName: "globe.badge.plus")
                            .font(.system(size: 28, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                    }
                    .accessibilityHidden(true)

                    VStack(spacing: 4) {
                        Text("No Domains Added")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("Add your first domain to start managing DNS records and edge security.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Button {
                        HapticManager.selection()
                        showingAddZone = true
                    } label: {
                        Label("Add Domain", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accentColor)
                    .padding(.top, 4)
                }
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.recentZones.enumerated()), id: \.element.id) { index, zone in
                        NavigationLink {
                            ZoneDetailView(zone: zone)
                        } label: {
                            HStack(spacing: 12) {
                                AccountAvatarView(identifier: zone.name, size: 36, showShadow: false)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(verbatim: zone.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)

                                    Text(zone.plan?.name ?? String(localized: "Free Plan"))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer(minLength: 8)

                                // 24h Traffic Sparkline mini chart
                                ZoneRowSparklineView(zoneId: zone.id, cached: viewModel.sparklines[zone.id])

                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                                    .accessibilityHidden(true)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < viewModel.recentZones.count - 1 {
                            Divider()
                                .padding(.leading, 62)
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
            }
        }
    }
}

// MARK: - DashboardMetricCardView (Native Inset Bento Tile)

struct DashboardMetricCardView: View {
    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
    let value: String
    let subtitle: LocalizedStringKey
    let badge: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [iconColor, iconColor.opacity(0.88)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .symbolRenderingMode(.hierarchical)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)

                Spacer()

                Text(badge)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .clipShape(Capsule())
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Text(value)
                .font(Font.system(.title2, design: .rounded).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.80)

            Spacer(minLength: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 114, alignment: .topLeading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }
}

// MARK: - QuickDeckButton (Apple HIG Clean Action Item)

struct QuickDeckButton: View {
    let icon: String
    let color: Color
    let title: LocalizedStringKey

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.88)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: color.opacity(0.20), radius: 4, x: 0, y: 2)

                Image(systemName: icon)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .hoverEffect(.lift)
    }
}
