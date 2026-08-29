import SwiftUI
import Combine

// MARK: - DashboardView (Apple HIG Native Polish)

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @ObservedObject private var accountManager = AccountManager.shared
    @State private var showingAccountSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // 1. Brand Hero Header
                        heroHeaderView
                        
                        // 2. Global Fleet Metrics Grid (2x2)
                        resourcesOverviewGridView
                        
                        // 3. Quick Command Deck
                        quickCommandDeckView
                        
                        // 4. Primary Active Domains (with Sparklines)
                        activeZonesSectionView
                        
                        // 5. Cloudflare Live Status Bar
                        systemStatusBannerView
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
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
                        Circle()
                            .fill(LinearGradient(gradient: Gradient(colors: [.blue, .cyan]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text(accountManager.activeEmail.prefix(1).uppercased())
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            )
                            .shadow(color: Color.blue.opacity(0.25), radius: 4, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Switch Cloudflare Account")
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
    
    // MARK: - 1. Hero Header
    private var heroHeaderView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.timeGreeting)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    Text(viewModel.selectedAccount?.name ?? "Cloudflare Account")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 8)
                
                NavigationLink(destination: CloudflareStatusView()) {
                    HIGBadge(.custom(color: .green, text: "Edge Optimal", icon: "checkmark.shield.fill"), isCompact: true)
                }
                .buttonStyle(.plain)
            }
            
            if let accountId = viewModel.selectedAccount?.id, !accountId.isEmpty {
                HStack(spacing: 6) {
                    Text("Account ID: \(accountId)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Button {
                        UIPasteboard.general.string = accountId
                        HIGFeedback.success()
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
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - 2. Resources Overview Cards Grid (2x2)
    private var resourcesOverviewGridView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 155, maximum: 240), spacing: 12)], spacing: 12) {
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
            .buttonStyle(.plain)
            
            NavigationLink(destination: DeveloperHubView()) {
                DashboardMetricCardView(
                    icon: "bolt.fill",
                    iconColor: .orange,
                    title: "Workers & Compute",
                    value: viewModel.hasFetchedData ? "\(viewModel.workers.count + viewModel.pages.count)" : "-",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.workers.count) W · \(viewModel.pages.count) P" : "Loading...",
                    badge: "Compute"
                )
            }
            .buttonStyle(.plain)
            
            NavigationLink(destination: KVBrowserView(accountId: viewModel.selectedAccount?.id ?? "")) {
                DashboardMetricCardView(
                    icon: "cylinder.split.1x2.fill",
                    iconColor: .purple,
                    title: "Storage & DB",
                    value: viewModel.hasFetchedData ? "\(viewModel.totalStorageCount)" : "-",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.kvCount) KV · \(viewModel.r2Count) R2 · \(viewModel.d1Count) D1" : "Loading...",
                    badge: "Storage"
                )
            }
            .buttonStyle(.plain)
            
            NavigationLink(destination: TunnelsListView(accountId: viewModel.selectedAccount?.id ?? "")) {
                DashboardMetricCardView(
                    icon: "shield.righthalf.filled",
                    iconColor: .green,
                    title: "Zero Trust Tunnels",
                    value: viewModel.hasFetchedData ? "\(viewModel.tunnels.count)" : "-",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.healthyTunnelsCount) Healthy" : "Loading...",
                    badge: "Tunnel"
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - 3. Quick Command Deck
    private var quickCommandDeckView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Diagnostics & Tools")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    NavigationLink(destination: AddZoneView()) {
                        QuickDeckButton(icon: "plus.circle.fill", color: .blue, title: "Add Domain")
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink(destination: DNSDigToolView()) {
                        QuickDeckButton(icon: "arrow.triangle.2.circlepath.circle.fill", color: .blue, title: "DoH Dig")
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink(destination: CFTraceToolView()) {
                        QuickDeckButton(icon: "antenna.radiowaves.left.and.right", color: .purple, title: "Edge Trace")
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink(destination: IPLookupToolView()) {
                        QuickDeckButton(icon: "network.badge.shield.half.filled", color: .indigo, title: "IP / ASN")
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink(destination: CertInspectToolView()) {
                        QuickDeckButton(icon: "lock.shield.fill", color: .cyan, title: "SSL Inspector")
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink(destination: WhoisToolView()) {
                        QuickDeckButton(icon: "magnifyingglass", color: .teal, title: "RDAP / WHOIS")
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink(destination: CIDRCalculatorView()) {
                        QuickDeckButton(icon: "rectangle.split.3x3.fill", color: .orange, title: "CIDR Calc")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
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
                
                NavigationLink(destination: ZonesListView()) {
                    HStack(spacing: 4) {
                        Text(viewModel.hasFetchedData ? "See All (\(viewModel.zones.count))" : "See All")
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 4)
            
            if !viewModel.hasFetchedData {
                VStack(spacing: 10) {
                    ForEach(Zone.placeholders.prefix(3)) { placeholderZone in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(.tertiarySystemFill))
                                .frame(width: 36, height: 36)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(placeholderZone.name)
                                    .font(.body.weight(.medium))
                                    .lineLimit(1)
                                
                                Text(placeholderZone.plan?.name ?? "Free Plan")
                                    .font(.caption2)
                            }
                            
                            Spacer()
                            
                            HIGBadge(.active, isCompact: true)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .redacted(reason: .placeholder)
            } else if viewModel.zones.isEmpty {
                HIGContentState(
                    .empty(
                        title: "No Domains Added",
                        systemImage: "globe.badge.chevron.backward",
                        description: "Add your first domain to start managing DNS records and edge security.",
                        actionTitle: "Add Domain",
                        action: {}
                    )
                )
                .padding(.vertical, 16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.recentZones) { zone in
                        NavigationLink(destination: ZoneDetailView(zone: zone)) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "globe")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(zone.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    
                                    Text(zone.plan?.name ?? "Free Plan")
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
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - 5. System Status Banner
    private var systemStatusBannerView: some View {
        NavigationLink(destination: CloudflareStatusView()) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cloudflare Operational Status")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("CDN, DNS, WAF and Global Edge Centers")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
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
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(iconColor)
                }
                .accessibilityHidden(true)
                
                Spacer()
                
                Text(badge)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
                    .lineLimit(1)
            }
            
            Spacer(minLength: 6)
            
            Text(value)
                .font(Font.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.80)
            
            Spacer(minLength: 6)
            
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
        .frame(maxWidth: .infinity, minHeight: 114, maxHeight: 114, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - QuickDeckButton (Inlined & Cohesive)

struct QuickDeckButton: View {
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
            }
            .accessibilityHidden(true)
            
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(width: 84)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
