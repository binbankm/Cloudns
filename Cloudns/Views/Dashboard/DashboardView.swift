import SwiftUI
import Combine

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var accountManager = AccountManager.shared
    @State private var showingAccountSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Brand Hero Header
                        heroHeaderView
                        
                        // 2. Global Fleet Metrics Grid (Adaptive 2x2 or 3x3)
                        resourcesOverviewGridView
                        
                        // 3. Quick Command Strip
                        quickCommandDeckView
                        
                        // 4. Primary Active Zones
                        activeZonesSectionView
                        
                        // 5. Cloudflare Live Status Bar
                        systemStatusBannerView
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                    .centerConstrainedWidth(maxWidth: 840)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.impact(.light)
                        showingAccountSheet = true
                    } label: {
                        Circle()
                            .fill(LinearGradient(gradient: Gradient(colors: [.orange, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text(accountManager.activeEmail.prefix(1).uppercased())
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            )
                            .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .transaction { $0.animation = nil }
                    .accessibilityLabel("Cloudflare Accounts")
                }
            }
            .sheet(isPresented: $showingAccountSheet) {
                AccountsView()
            }
            .refreshable {
                await viewModel.fetchDashboard(isRefresh: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: .accountSwitched)) { _ in
                Task { await viewModel.fetchDashboard(isRefresh: true) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .appWillEnterForeground)) { _ in
                if viewModel.isStale {
                    Task { await viewModel.fetchDashboard(isRefresh: true) }
                }
            }
            .task {
                if !viewModel.hasFetchedData || viewModel.isStale {
                    await viewModel.fetchDashboard()
                }
            }
        }
    }
    
    // MARK: - 1. Hero Header
    private var heroHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.timeGreeting)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(viewModel.selectedAccount?.name ?? "Cloudflare Account")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                NavigationLink(destination: CloudflareStatusView()) {
                    CloudnsBadge(.active("Edge: Optimal"), isCompact: true)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if let accountId = viewModel.selectedAccount?.id, !accountId.isEmpty {
                HStack(spacing: 6) {
                    Text("ID: \(accountId)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Button {
                        UIPasteboard.general.string = accountId
                        HapticManager.impact(.light)
                        ToastManager.shared.showCopied("Account ID copied")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, -4)
            }
        }
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - 2. Resources Overview Cards Grid
    private var resourcesOverviewGridView: some View {
        LazyVGrid(columns: GridItem.cloudnsAdaptiveMetrics, spacing: 12) {
            NavigationLink(destination: ZonesListView()) {
                DashboardMetricCard(
                    icon: "globe",
                    iconColor: .blue,
                    title: "Active Zones",
                    value: viewModel.hasFetchedData ? "\(viewModel.activeZonesCount)" : "-",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.zones.count) Total Zones" : "Loading...",
                    badge: "DNS"
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: DeveloperHubView()) {
                DashboardMetricCard(
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
                DashboardMetricCard(
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
                DashboardMetricCard(
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
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Diagnostics & Tools")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
                        QuickDeckButton(icon: "person.text.rectangle.fill", color: .teal, title: "WHOIS")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: WorkersAIView(accountId: viewModel.selectedAccount?.id ?? "")) {
                        QuickDeckButton(icon: "sparkles", color: .orange, title: "Workers AI")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 2)
            }
        }
    }
    
    // MARK: - 4. Active Zones Section
    private var activeZonesSectionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Active Domains")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                NavigationLink(destination: ZonesListView()) {
                    Text(viewModel.hasFetchedData ? "See All (\(viewModel.zones.count))" : "See All")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 4)
            
            if !viewModel.hasFetchedData {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(24)
                    Spacer()
                }
                .cloudnsCard(style: .frosted, cornerRadius: 16)
            } else if viewModel.zones.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "globe.badge.chevron.backward")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Domains Added Yet")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .cloudnsCard(style: .frosted, cornerRadius: 16)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.zones.prefix(3)) { zone in
                        NavigationLink(destination: ZoneDetailView(zone: zone)) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.orange.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "globe")
                                        .font(.subheadline)
                                        .foregroundStyle(.orange)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(zone.name)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    
                                    Text(zone.plan?.name ?? "Free Plan")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                CloudnsBadge(zone.status.lowercased() == "active" ? .active("Active") : .warning(zone.status.capitalized), isCompact: true)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .accessibilityHidden(true)
                            }
                            .padding(12)
                            .cloudnsCard(style: .frosted, cornerRadius: 14)
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
            HStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cloudflare Operational Status")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text("CDN, DNS, WAF and Global Edge Centers")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .cloudnsCard(style: .frosted, cornerRadius: 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Dashboard Components

struct DashboardMetricCard: View {
    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
    let value: String
    let subtitle: LocalizedStringKey
    let badge: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(iconColor)
                }
                .accessibilityHidden(true)
                
                Spacer()
                
                Text(badge)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            
            CloudnsRollingNumber(
                value: value,
                font: .system(.title2, design: .rounded),
                weight: .bold,
                color: .primary
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 148, maxHeight: 148)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
}

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
        .frame(width: 82)
        .padding(.vertical, 10)
        .cloudnsCard(style: .frosted, cornerRadius: 14)
    }
}
