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
                        
                        // 2. Global Fleet Metrics Grid (2x2)
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
                    .padding(.bottom, 30)
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
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchDashboard()
                }
            }
        }
    }
    
    // MARK: - 1. Hero Header
    private var heroHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
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
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Edge: Optimal")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        .skeletonLoading(!viewModel.hasFetchedData)
    }
    
    // MARK: - 2. Resources Overview Cards Grid
    private var resourcesOverviewGridView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            NavigationLink(destination: ZonesListView()) {
                DashboardMetricCard(
                    icon: "network",
                    iconColor: .blue,
                    title: "Active Zones",
                    value: viewModel.hasFetchedData ? "\(viewModel.activeZonesCount)" : "3",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.zones.count) Total Zones" : "3 Total Zones",
                    badge: "DNS"
                )
                .skeletonLoading(!viewModel.hasFetchedData)
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: DeveloperHubView()) {
                DashboardMetricCard(
                    icon: "cpu",
                    iconColor: .orange,
                    title: "Workers & Pages",
                    value: viewModel.hasFetchedData ? "\(viewModel.workers.count + viewModel.pages.count)" : "6",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.workers.count) W · \(viewModel.pages.count) P" : "4 W · 2 P",
                    badge: "Compute"
                )
                .skeletonLoading(!viewModel.hasFetchedData)
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: KVBrowserView(accountId: viewModel.selectedAccount?.id ?? "")) {
                DashboardMetricCard(
                    icon: "cylinder.split.1x2",
                    iconColor: .purple,
                    title: "Cloud Storage",
                    value: viewModel.hasFetchedData ? "\(viewModel.totalStorageCount)" : "8",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.kvCount) KV · \(viewModel.r2Count) R2 · \(viewModel.d1Count) D1" : "3 KV · 3 R2 · 2 D1",
                    badge: "Storage"
                )
                .skeletonLoading(!viewModel.hasFetchedData)
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: TunnelsListView(accountId: viewModel.selectedAccount?.id ?? "")) {
                DashboardMetricCard(
                    icon: "shield.righthalf.filled",
                    iconColor: .green,
                    title: "Zero Trust Tunnels",
                    value: viewModel.hasFetchedData ? "\(viewModel.tunnels.count)" : "2",
                    subtitle: viewModel.hasFetchedData ? "\(viewModel.healthyTunnelsCount) Healthy Connectors" : "2 Healthy Connectors",
                    badge: "Cloudflared"
                )
                .skeletonLoading(!viewModel.hasFetchedData)
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
                Text("Active Zones")
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
                VStack(spacing: 8) {
                    ForEach(Zone.placeholders.prefix(3)) { zone in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(zone.name)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                
                                Text(zone.plan?.name ?? "Pro Plan")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color(.tertiaryLabel))
                                .accessibilityHidden(true)
                        }
                        .padding(14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .skeletonLoading(true)
            } else if viewModel.zones.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text("No domain zones loaded")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.zones.prefix(3)) { zone in
                        NavigationLink(destination: ZoneDetailView(zone: zone)) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(zone.status.lowercased() == "active" ? Color.green : Color.orange)
                                    .frame(width: 8, height: 8)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(zone.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    if let plan = zone.plan?.name {
                                        Text(plan)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(Color(.tertiaryLabel))
                                    .accessibilityHidden(true)
                            }
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text("CDN, DNS, WAF and Global Edge Centers")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("View")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
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
    let badge: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)
                    .background(iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)
                
                Spacer()
                
                Text(badge)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .medium))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 125, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
    }
}

struct QuickDeckButton: View {
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(Circle())
                .accessibilityHidden(true)
            
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(width: 78)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
