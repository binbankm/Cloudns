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
                        
                        // 3. Interactive Zone Analytics Chart (Swift Charts)
                        DashboardZoneTrafficChartView(viewModel: viewModel)
                        
                        // 4. Quick Command Deck (Bento Grid)
                        quickCommandDeckView
                        
                        // 5. Primary Active Domains (with Sparklines)
                        activeZonesSectionView
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
                        AccountAvatarView(identifier: accountManager.activeEmail, size: 30)
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
        VStack(alignment: .leading, spacing: 14) {
            // Top Row: Greeting & Identity
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: greetingIcon)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                    
                    Text(viewModel.timeGreeting)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                
                Text(viewModel.selectedAccount?.name ?? (accountManager.activeEmail.isEmpty ? "Cloudflare Account" : accountManager.activeEmail))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if !accountManager.activeEmail.isEmpty && viewModel.selectedAccount?.name != accountManager.activeEmail {
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
                        HIGFeedback.impact(.light)
                        UIPasteboard.general.string = accountId
                        ToastManager.shared.showCopied("Account ID Copied")
                    } label: {
                        HStack(spacing: 5) {
                            Text("ID")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.orange.opacity(0.18))
                                .foregroundStyle(.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                            
                            Text(accountId.prefix(8) + "..." + accountId.suffix(4))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                            
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary.opacity(0.8))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Account ID: \(accountId), tap to copy")
                }
                
                Spacer(minLength: 4)
                
                HStack(spacing: 5) {
                    Image(systemName: "shield.checkerboard")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.blue)
                    
                    Text("Zero Trust Edge")
                        .font(.system(size: 11, weight: .medium))
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
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.35),
                                    Color.blue.opacity(0.15),
                                    Color(.separator).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
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
    
    // MARK: - 3. Quick Command Deck (Bento Grid)
    private var quickCommandDeckView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Quick Diagnostics & Tools")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                NavigationLink(destination: NetworkToolsView()) {
                    HStack(spacing: 4) {
                        Text("All Tools")
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 14) {
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
                
                NavigationLink(destination: CertInspectToolView()) {
                    QuickDeckButton(icon: "lock.shield.fill", color: .cyan, title: "SSL Inspect")
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
                    QuickDeckButton(icon: "speedometer", color: .orange, title: "Latency")
                }
                .buttonStyle(.plain)
                
                NavigationLink(destination: CIDRCalculatorView()) {
                    QuickDeckButton(icon: "rectangle.split.3x3.fill", color: .green, title: "CIDR Calc")
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                HStack {
                    Spacer()
                    ProgressView("Loading Domains...")
                        .padding(.vertical, 32)
                    Spacer()
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.recentZones.enumerated()), id: \.element.id) { index, zone in
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
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

// MARK: - QuickDeckButton (Apple HIG Clean Action Item)

struct QuickDeckButton: View {
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.14))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(color)
            }
            .accessibilityHidden(true)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
