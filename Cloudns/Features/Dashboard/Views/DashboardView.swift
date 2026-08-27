import SwiftUI
import Combine

struct DashboardView: View {
    // MARK: - Properties
    @StateObject private var viewModel = DashboardViewModel()
    @ObservedObject private var accountManager = AccountManager.shared
    @State private var showingAccountSheet = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                CloudnsColor.groupedBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: CloudnsSpacing.mdMedium) {
                        // 1. Brand Hero Header
                        heroHeaderView
                        
                        // 2. Global Fleet Metrics Grid (Compact 2x2, 114pt height, non-truncating)
                        resourcesOverviewGridView
                        
                        // 3. Quick Command Deck
                        quickCommandDeckView
                        
                        // 4. Primary Active Domains (with Sparkline mini charts)
                        activeZonesSectionView
                        
                        // 5. Cloudflare Live Status Bar
                        systemStatusBannerView
                    }
                    .padding(.horizontal, CloudnsSpacing.md)
                    .padding(.top, CloudnsSpacing.sm)
                    .padding(.bottom, CloudnsSpacing.xl)
                    .centerConstrainedWidth(maxWidth: 840)
                }
                .refreshable {
                    HapticManager.impact(.light)
                    await viewModel.fetchDashboard(isRefresh: true)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.impact(.light)
                        showingAccountSheet = true
                    } label: {
                        Circle()
                            .fill(LinearGradient(gradient: Gradient(colors: [.blue, .cyan]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: CloudnsSize.avatarSmall, height: CloudnsSize.avatarSmall)
                            .overlay(
                                Text(accountManager.activeEmail.prefix(1).uppercased())
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            )
                            .cloudnsShadow(.brand(color: CloudnsColor.brand, radius: 4, y: 1))
                    }
                    .buttonStyle(.plain)
                    .transaction { $0.animation = nil }
                    .accessibilityLabel("Cloudflare Accounts")
                }
            }
            .sheet(isPresented: $showingAccountSheet) {
                AccountsView()
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
    
    // MARK: - 1. Hero Header (Compact & Crisp)
    private var heroHeaderView: some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
                    Text(viewModel.timeGreeting)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    Text(viewModel.selectedAccount?.name ?? "Cloudflare Account")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: CloudnsSpacing.sm)
                
                NavigationLink(destination: CloudflareStatusView()) {
                    CloudnsBadge(.active("Edge: Optimal"), isCompact: true)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if let accountId = viewModel.selectedAccount?.id, !accountId.isEmpty {
                HStack(spacing: CloudnsSpacing.sm) {
                    Text("ID: \(accountId)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Button {
                        UIPasteboard.general.string = accountId
                        HapticManager.impact(.light)
                        CloudnsToastManager.shared.showCopied("Account ID copied")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Copy Account ID")
                }
            }
        }
        .padding(CloudnsSpacing.mdMedium)
        .background(
            RoundedRectangle(cornerRadius: CloudnsRadius.lg, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - 2. Resources Overview Cards Grid (114pt Symmetrical)
    private var resourcesOverviewGridView: some View {
        LazyVGrid(columns: GridItem.cloudnsAdaptiveMetrics, spacing: CloudnsSpacing.smMd) {
            NavigationLink(destination: ZonesListView()) {
                DashboardMetricCardView(
                    icon: "globe",
                    iconColor: .blue,
                    title: "Active Zones",
                    value: viewModel.hasFetchedData ? "\(viewModel.activeZonesCount)" : "-",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.zones.count) Total Zones" : "Loading...",
                    badge: "Domains"
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: DeveloperHubView()) {
                DashboardMetricCardView(
                    icon: "cpu.fill",
                    iconColor: .orange,
                    title: "Workers & Pages",
                    value: viewModel.hasFetchedData ? "\(viewModel.workers.count + viewModel.pages.count)" : "-",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.workers.count) W · \(viewModel.pages.count) P" : "Loading...",
                    badge: "Compute"
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: KVBrowserView(accountId: viewModel.selectedAccount?.id ?? "")) {
                DashboardMetricCardView(
                    icon: "cylinder.split.1x2.fill",
                    iconColor: .purple,
                    title: "Cloud Storage",
                    value: viewModel.hasFetchedData ? "\(viewModel.totalStorageCount)" : "-",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.kvCount) KV · \(viewModel.r2Count) R2 · \(viewModel.d1Count) D1" : "Loading...",
                    badge: "Storage"
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: TunnelsListView(accountId: viewModel.selectedAccount?.id ?? "")) {
                DashboardMetricCardView(
                    icon: "shield.righthalf.filled",
                    iconColor: .green,
                    title: "Zero Trust Tunnels",
                    value: viewModel.hasFetchedData ? "\(viewModel.tunnels.count)" : "-",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.healthyTunnelsCount) Healthy Connectors" : "Loading...",
                    badge: "Tunnel"
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - 3. Quick Command Deck
    private var quickCommandDeckView: some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
            Text("Quick Diagnostics & Tools")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, CloudnsSpacing.xs)
            
            ScrollView(.horizontal) {
                LazyHStack(spacing: CloudnsSpacing.smMd) {
                    NavigationLink(destination: CFTraceToolView()) {
                        QuickDeckButton(icon: "antenna.radiowaves.left.and.right", color: .purple, title: "Edge Trace")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: DNSDigToolView()) {
                        QuickDeckButton(icon: "arrow.triangle.2.circlepath.circle.fill", color: .blue, title: "DoH Dig")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: IPLookupToolView()) {
                        QuickDeckButton(icon: "network.badge.shield.half.filled", color: .indigo, title: "IP / ASN")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: CertInspectToolView()) {
                        QuickDeckButton(icon: "lock.shield.fill", color: .cyan, title: "SSL Inspector")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: WhoisToolView()) {
                        QuickDeckButton(icon: "magnifyingglass", color: .teal, title: "RDAP / WHOIS")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: CIDRCalculatorView()) {
                        QuickDeckButton(icon: "rectangle.split.3x3.fill", color: .orange, title: "CIDR Calc")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: DevToolsHubView()) {
                        QuickDeckButton(icon: "wrench.and.screwdriver.fill", color: .pink, title: "All Tools")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, CloudnsSpacing.xs)
                .padding(.vertical, CloudnsSpacing.xs)
            }
            .scrollIndicators(.hidden)
        }
    }
    
    // MARK: - 4. Recent Domains Section (with Real Sparkline Live Charts)
    private var activeZonesSectionView: some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
            HStack {
                Text("Recent Domains")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                NavigationLink(destination: ZonesListView()) {
                    HStack(spacing: CloudnsSpacing.xxs) {
                        Text(viewModel.hasFetchedData ? "See All (\(viewModel.zones.count))" : "See All")
                        Image(systemName: "chevron.right")
                            .font(CloudnsTypography.caption2.weight(.bold))
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(CloudnsColor.brand)
                }
            }
            .padding(.horizontal, CloudnsSpacing.xs)
            
            if !viewModel.hasFetchedData {
                VStack(spacing: CloudnsSpacing.sm) {
                    ForEach(Zone.placeholders.prefix(3)) { placeholderZone in
                        HStack(spacing: CloudnsSpacing.smMd) {
                            Circle()
                                .fill(Color(.tertiarySystemFill))
                                .frame(width: CloudnsSize.controlHeightSmall, height: CloudnsSize.controlHeightSmall)
                            
                            VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
                                Text(placeholderZone.name)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                
                                Text(placeholderZone.plan?.name ?? "Free Plan")
                                    .font(.caption2)
                            }
                            
                            Spacer()
                            
                            CloudnsBadge(.active("Active"), isCompact: true)
                        }
                        .padding(CloudnsSpacing.smMd)
                        .cloudnsCard(style: .frosted, size: .compact)
                    }
                }
                .skeletonLoading(true)
            } else if viewModel.zones.isEmpty {
                VStack(spacing: CloudnsSpacing.smMd) {
                    Image(systemName: "globe.badge.chevron.backward")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No Domains Added Yet")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, CloudnsSpacing.lg)
                .cloudnsCard(style: .frosted, size: .compact)
            } else {
                VStack(spacing: CloudnsSpacing.sm) {
                    ForEach(viewModel.recentZones) { zone in
                        NavigationLink(destination: ZoneDetailView(zone: zone)) {
                            HStack(spacing: CloudnsSpacing.smMd) {
                                ZStack {
                                    Circle()
                                        .fill(CloudnsColor.brandMuted)
                                        .frame(width: CloudnsSize.controlHeightSmall, height: CloudnsSize.controlHeightSmall)
                                    Image(systemName: "globe")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(CloudnsColor.brand)
                                }
                                
                                VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
                                    Text(zone.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                    
                                    Text(zone.plan?.name ?? "Free Plan")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer(minLength: CloudnsSpacing.sm)
                                
                                // 24h Traffic Sparkline mini chart (bound to live SWR cache)
                                ZoneRowSparklineView(zoneId: zone.id, cached: viewModel.sparklines[zone.id])
                                
                                Image(systemName: "chevron.right")
                                    .font(CloudnsTypography.caption2.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                                    .accessibilityHidden(true)
                            }
                            .padding(CloudnsSpacing.smMd)
                            .cloudnsCard(style: .frosted, size: .compact)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - 5. System Status Banner
    private var systemStatusBannerView: some View {
        NavigationLink(destination: CloudflareStatusView()) {
            HStack(spacing: CloudnsSpacing.smMd) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloudnsColor.success)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
                    Text("Cloudflare Operational Status")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("CDN, DNS, WAF and Global Edge Centers")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(CloudnsTypography.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(CloudnsSpacing.mdSmall)
            .cloudnsCard(style: .frosted, size: .compact)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
