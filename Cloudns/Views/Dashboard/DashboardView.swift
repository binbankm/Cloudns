import SwiftUI
import Combine

// MARK: - DashboardView (Apple HIG Native Polish)
// Bento Grid, Dynamic Theme, Live Analytics & 44pt Touch Targets

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @ObservedObject private var accountManager = AccountManager.shared
    @State private var showingAccountSheet = false
    @State private var showingAddZone = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.higGroupBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: HIGTokens.Spacing.lg) {
                        // 1. Brand Hero Header
                        heroHeaderView
                        
                        // 2. Global Fleet Metrics Grid (2x2)
                        resourcesOverviewGridView
                        
                        // 3. Interactive Zone Analytics Chart (Swift Charts)
                        DashboardZoneTrafficChartView(viewModel: viewModel)
                        
                        // 4. Quick Command Deck (Bento Grid)
                        quickCommandDeckView
                        
                        // 5. Primary Active Domains (with Sparklines)
                        activeZonesSectionView
                    }
                    .padding(.horizontal, HIGTokens.Spacing.lg)
                    .padding(.top, HIGTokens.Spacing.sm)
                    .padding(.bottom, HIGTokens.Spacing.xxl)
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
                        HIGFeedback.impact(.light)
                        showingAccountSheet = true
                    } label: {
                        AccountAvatarView(identifier: accountManager.activeEmail, size: HIGTokens.Size.avatarSmall)
                    }
                    .buttonStyle(.plain)
                    .higTouchTarget()
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
    
    // MARK: - 1. Professional Hero Header
    private var heroHeaderView: some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.md) {
            // Top Row: Greeting & Identity
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                HStack(spacing: HIGTokens.Spacing.xs) {
                    Image(systemName: greetingIcon)
                        .font(HIGTypography.caption2.weight(.semibold))
                        .foregroundStyle(Color.higAccent)
                    
                    Text(viewModel.timeGreeting)
                        .font(HIGTypography.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                
                Text(viewModel.selectedAccount?.name ?? (accountManager.activeEmail.isEmpty ? "Cloudflare Account" : accountManager.activeEmail))
                    .font(HIGTypography.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if !accountManager.activeEmail.isEmpty && viewModel.selectedAccount?.name != accountManager.activeEmail {
                    Text(accountManager.activeEmail)
                        .font(HIGTypography.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Divider()
                .opacity(0.6)
            
            // Bottom Meta Bar: Account ID Capsule & Architecture Level
            HStack(spacing: HIGTokens.Spacing.sm) {
                if let accountId = viewModel.selectedAccount?.id, !accountId.isEmpty {
                    Button {
                        HIGFeedback.copied()
                        UIPasteboard.general.string = accountId
                        ToastManager.shared.showCopied("Account ID Copied")
                    } label: {
                        HStack(spacing: HIGTokens.Spacing.xs) {
                            Text("ID")
                                .font(HIGTypography.caption2.weight(.bold).monospaced())
                                .padding(.horizontal, HIGTokens.Spacing.xxs + 2)
                                .padding(.vertical, 1)
                                .background(Color.higAccent.opacity(0.18))
                                .foregroundStyle(Color.higAccent)
                                .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.xs, style: .continuous))
                            
                            Text(accountId.prefix(8) + "..." + accountId.suffix(4))
                                .font(HIGTypography.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                            
                            Image(systemName: "doc.on.doc")
                                .font(HIGTypography.caption2)
                                .foregroundStyle(.secondary.opacity(0.8))
                        }
                        .padding(.horizontal, HIGTokens.Spacing.sm)
                        .padding(.vertical, HIGTokens.Spacing.xs)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Account ID: \(accountId), tap to copy")
                }
                
                Spacer(minLength: HIGTokens.Spacing.xxs)
                
                HStack(spacing: HIGTokens.Spacing.xs) {
                    Image(systemName: "shield.checkerboard")
                        .font(HIGTypography.caption2.weight(.semibold))
                        .foregroundStyle(.blue)
                    
                    Text("Zero Trust Edge")
                        .font(HIGTypography.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, HIGTokens.Spacing.sm)
                .padding(.vertical, HIGTokens.Spacing.xs)
                .background(Color.blue.opacity(0.08))
                .clipShape(Capsule())
            }
        }
        .padding(HIGTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous)
                .fill(Color.higCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.higAccent.opacity(0.35),
                                    Color.blue.opacity(0.15),
                                    Color(.separator).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: Color.black.opacity(0.03), radius: HIGTokens.Elevation.cardShadowRadius, x: 0, y: 2)
        )
    }
    
    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "sun.max.fill"
        case 12..<18:
            return "sun.haze.fill"
        default:
            return "moon.stars.fill"
        }
    }
    
    // MARK: - 2. Resources Overview Cards Grid (2x2)
    private var resourcesOverviewGridView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 155, maximum: 240), spacing: HIGTokens.Spacing.md)], spacing: HIGTokens.Spacing.md) {
            NavigationLink {
                ZonesListView()
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
            .buttonStyle(.higCard)
            
            NavigationLink {
                DeveloperHubView()
            } label: {
                DashboardMetricCardView(
                    icon: "bolt.fill",
                    iconColor: Color.higAccent,
                    title: "Workers & Pages",
                    value: viewModel.hasFetchedData ? "\(viewModel.workers.count + viewModel.pages.count)" : "-",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.workers.count) Workers · \(viewModel.pages.count) Pages" : "Loading…",
                    badge: "Compute"
                )
            }
            .buttonStyle(.higCard)
            
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
            .buttonStyle(.higCard)
            
            NavigationLink {
                if let accId = viewModel.selectedAccount?.id, !accId.isEmpty {
                    TunnelsListView(accountId: accId)
                } else {
                    TunnelsListView(accountId: "current")
                }
            } label: {
                DashboardMetricCardView(
                    icon: "shield.righthalf.filled",
                    iconColor: HIGColors.success,
                    title: "Zero Trust Tunnels",
                    value: viewModel.hasFetchedData ? "\(viewModel.tunnels.count)" : "-",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.healthyTunnelsCount) Healthy" : "Loading…",
                    badge: "Tunnel"
                )
            }
            .buttonStyle(.higCard)
        }
    }
    
    // MARK: - 3. Quick Command Deck (Bento Grid)
    private var quickCommandDeckView: some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.sm + 2) {
            HStack {
                Text("Quick Diagnostics & Tools")
                    .font(HIGTypography.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                NavigationLink(destination: NetworkToolsView()) {
                    HStack(spacing: HIGTokens.Spacing.xxs) {
                        Text("All Tools")
                        Image(systemName: "chevron.forward")
                            .font(HIGTypography.caption2.weight(.bold))
                    }
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(Color.higAccent)
                }
            }
            .padding(.horizontal, HIGTokens.Spacing.xxs)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: HIGTokens.Spacing.sm + 2), count: 4), spacing: HIGTokens.Spacing.md + 2) {
                NavigationLink(destination: AddZoneView()) {
                    QuickDeckButton(icon: "plus.circle.fill", color: Color.higAccent, title: "Add Domain")
                }
                .buttonStyle(.higPressable)
                
                NavigationLink(destination: DNSDigToolView()) {
                    QuickDeckButton(icon: "arrow.triangle.2.circlepath.circle.fill", color: .blue, title: "DNS Dig")
                }
                .buttonStyle(.higPressable)
                
                NavigationLink(destination: CFTraceToolView()) {
                    QuickDeckButton(icon: "antenna.radiowaves.left.and.right", color: .purple, title: "Edge Trace")
                }
                .buttonStyle(.higPressable)
                
                NavigationLink(destination: CertInspectToolView()) {
                    QuickDeckButton(icon: "lock.shield.fill", color: .cyan, title: "SSL Check")
                }
                .buttonStyle(.higPressable)
                
                NavigationLink(destination: IPLookupToolView()) {
                    QuickDeckButton(icon: "network.badge.shield.half.filled", color: .indigo, title: "IP / ASN")
                }
                .buttonStyle(.higPressable)
                
                NavigationLink(destination: WhoisToolView()) {
                    QuickDeckButton(icon: "magnifyingglass", color: .teal, title: "WHOIS")
                }
                .buttonStyle(.higPressable)
                
                NavigationLink(destination: EdgeLatencyTestView()) {
                    QuickDeckButton(icon: "speedometer", color: Color.higAccent, title: "Latency Test")
                }
                .buttonStyle(.higPressable)
                
                NavigationLink(destination: CIDRCalculatorView()) {
                    QuickDeckButton(icon: "rectangle.split.3x3.fill", color: HIGColors.success, title: "CIDR Calc")
                }
                .buttonStyle(.higPressable)
            }
            .padding(.vertical, HIGTokens.Spacing.md + 2)
            .padding(.horizontal, HIGTokens.Spacing.sm + 2)
            .background(Color.higCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
        }
    }
    
    // MARK: - 4. Recent Domains Section
    private var activeZonesSectionView: some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.sm + 2) {
            HStack {
                Text("Recent Domains")
                    .font(HIGTypography.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                NavigationLink(destination: ZonesListView()) {
                    HStack(spacing: HIGTokens.Spacing.xxs) {
                        Text(viewModel.hasFetchedData ? "See All (\(viewModel.zones.count))" : "See All")
                        Image(systemName: "chevron.right")
                            .font(HIGTypography.caption2.weight(.bold))
                    }
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(Color.higAccent)
                }
            }
            .padding(.horizontal, HIGTokens.Spacing.xxs)
            
            if !viewModel.hasFetchedData {
                HStack {
                    Spacer()
                    ProgressView("Loading Domains…")
                        .padding(.vertical, HIGTokens.Spacing.xxl)
                    Spacer()
                }
                .background(Color.higCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
            } else if viewModel.zones.isEmpty {
                HIGContentState(
                    .empty(
                        title: "No Domains Added",
                        systemImage: "globe.badge.plus",
                        description: "Add your first domain to start managing DNS records and edge security.",
                        actionTitle: "Add Domain",
                        action: { showingAddZone = true }
                    )
                )
                .padding(.vertical, HIGTokens.Spacing.lg)
                .background(Color.higCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.recentZones.enumerated()), id: \.element.id) { index, zone in
                        NavigationLink(destination: ZoneDetailView(zone: zone)) {
                            HStack(spacing: HIGTokens.Spacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(AccountAvatarView.color(for: zone.name).opacity(0.14))
                                        .frame(width: HIGTokens.Size.avatarSmall + 2, height: HIGTokens.Size.avatarSmall + 2)
                                    Image(systemName: "globe")
                                        .font(HIGTypography.subheadline.weight(.semibold))
                                        .foregroundStyle(AccountAvatarView.color(for: zone.name))
                                }
                                
                                VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                                    Text(verbatim: zone.name)
                                        .font(HIGTypography.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    
                                    Text(zone.plan?.name ?? "Free Plan")
                                        .font(HIGTypography.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer(minLength: HIGTokens.Spacing.sm)
                                
                                // 24h Traffic Sparkline mini chart
                                ZoneRowSparklineView(zoneId: zone.id, cached: viewModel.sparklines[zone.id])
                                
                                Image(systemName: "chevron.right")
                                    .font(HIGTypography.caption2.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                                    .accessibilityHidden(true)
                            }
                            .padding(.horizontal, HIGTokens.Spacing.md + 2)
                            .padding(.vertical, HIGTokens.Spacing.sm + 3)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        if index < viewModel.recentZones.count - 1 {
                            Divider()
                                .padding(.leading, 62)
                        }
                    }
                }
                .background(Color.higCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
            }
        }
    }
}

// MARK: - DashboardMetricCardView (Inlined & Cohesive)

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
                    Circle()
                        .fill(iconColor.opacity(0.14))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(HIGTypography.caption.weight(.semibold))
                        .foregroundStyle(iconColor)
                }
                .accessibilityHidden(true)
                
                Spacer()
                
                Text(badge)
                    .font(HIGTypography.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, HIGTokens.Spacing.xs + 2)
                    .padding(.vertical, HIGTokens.Spacing.xxs)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
                    .lineLimit(1)
            }
            
            Spacer(minLength: HIGTokens.Spacing.xs)
            
            Text(value)
                .font(Font.system(.title2, design: .rounded).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.80)
            
            Spacer(minLength: HIGTokens.Spacing.xs)
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text(title)
                    .font(HIGTypography.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(HIGTypography.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(HIGTokens.Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 114, maxHeight: 114, alignment: .topLeading)
        .background(Color.higCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
    }
}

// MARK: - QuickDeckButton (Apple HIG Clean Action Item)

struct QuickDeckButton: View {
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    
    var body: some View {
        VStack(spacing: HIGTokens.Spacing.xs + 2) {
            ZStack {
                RoundedRectangle(cornerRadius: HIGTokens.Radius.md, style: .continuous)
                    .fill(color.opacity(0.14))
                    .frame(width: HIGTokens.Size.minTouchTarget, height: HIGTokens.Size.minTouchTarget)
                
                Image(systemName: icon)
                    .font(HIGTypography.body.weight(.semibold))
                    .foregroundStyle(color)
            }
            .accessibilityHidden(true)
            
            Text(title)
                .font(HIGTypography.caption2.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HIGTokens.Spacing.xxs)
        .contentShape(Rectangle())
    }
}
