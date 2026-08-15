import SwiftUI
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var accounts: [Account] = []
    @Published var selectedAccount: Account?
    
    @Published var zones: [Zone] = []
    @Published var workers: [WorkerScript] = []
    @Published var pages: [PagesProject] = []
    @Published var tunnels: [CFTunnel] = []
    
    @Published var kvCount: Int = 0
    @Published var r2Count: Int = 0
    @Published var d1Count: Int = 0
    
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    var activeZonesCount: Int {
        zones.filter { $0.status.lowercased() == "active" }.count
    }
    
    var healthyTunnelsCount: Int {
        tunnels.filter { $0.isHealthy }.count
    }
    
    var totalStorageCount: Int {
        kvCount + r2Count + d1Count
    }
    
    var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<18: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    func fetchDashboard(isRefresh: Bool = false) async {
        if !isRefresh && hasFetchedData { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Fetch accounts
            let fetchedAccounts = try await apiClient.getAccounts()
            self.accounts = fetchedAccounts
            
            let activeEmail = UserDefaults.standard.string(forKey: "activeAccountEmail") ?? ""
            let currentAcc = fetchedAccounts.first(where: { $0.name == activeEmail || $0.id == activeEmail }) ?? fetchedAccounts.first
            self.selectedAccount = currentAcc
            
            // 2. Concurrently fetch all resources
            let (fetchedZones, _) = (try? await apiClient.getZones()) ?? ([], nil)
            self.zones = fetchedZones
            
            if let accountId = currentAcc?.id, !accountId.isEmpty {
                async let fetchW = (try? await apiClient.getWorkers(accountId: accountId)) ?? []
                async let fetchP = (try? await apiClient.getPagesProjects(accountId: accountId)) ?? []
                async let fetchT = (try? await apiClient.getTunnels(accountId: accountId)) ?? []
                async let fetchK = (try? await apiClient.getKVNamespaces(accountId: accountId)) ?? []
                async let fetchR = (try? await apiClient.getR2Buckets(accountId: accountId)) ?? []
                async let fetchD = (try? await apiClient.getD1Databases(accountId: accountId)) ?? []
                
                let (w, p, t, k, r, d) = await (fetchW, fetchP, fetchT, fetchK, fetchR, fetchD)
                
                self.workers = w
                self.pages = p
                self.tunnels = t
                self.kvCount = k.count
                self.r2Count = r.count
                self.d1Count = d.count
            }
            
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var accountManager = AccountManager.shared
    @State private var showingAccountSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Brand Hero Header
                        heroHeaderView
                        
                        // 2. Global Fleet Metrics Grid (2x2)
                        metricsMatrixView
                        
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
                    NavigationLink(destination: AccountsView()) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: [.orange, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Text(accountManager.activeEmail.prefix(1).uppercased())
                                        .font(.caption2.weight(.medium))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
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
                        .foregroundColor(.secondary)
                    
                    Text(accountManager.activeEmail.isEmpty ? "Cloudflare Command" : accountManager.activeEmail)
                        .font(.title3)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Edge Network Status Pill
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                        .shadow(color: Color.green.opacity(0.8), radius: 3)
                    
                    Text("Edge: Optimal")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 2. 2x2 Metrics Matrix
    private var metricsMatrixView: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            // Card 1: Zones
            NavigationLink(destination: ZonesListView()) {
                DashboardMetricCard(
                    icon: "network",
                    iconColor: .blue,
                    title: "Managed Domains",
                    value: "\(viewModel.zones.count)",
                    subtitle: "\(viewModel.activeZonesCount) Active Online",
                    badge: "Zones"
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Card 2: Workers & Pages
            NavigationLink(destination: WorkersListView(accountId: viewModel.selectedAccount?.id ?? "")) {
                DashboardMetricCard(
                    icon: "bolt.fill",
                    iconColor: .orange,
                    title: "Edge Compute",
                    value: "\(viewModel.workers.count + viewModel.pages.count)",
                    subtitle: "\(viewModel.workers.count) Workers · \(viewModel.pages.count) Pages",
                    badge: "Serverless"
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Card 3: Storage Array
            NavigationLink(destination: DeveloperHubView()) {
                DashboardMetricCard(
                    icon: "cylinder.split.1x2.fill",
                    iconColor: .purple,
                    title: "Storage Engine",
                    value: "\(viewModel.totalStorageCount)",
                    subtitle: "\(viewModel.kvCount) KV · \(viewModel.r2Count) R2 · \(viewModel.d1Count) D1",
                    badge: "Databases"
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Card 4: Tunnels
            NavigationLink(destination: TunnelsListView(accountId: viewModel.selectedAccount?.id ?? "")) {
                DashboardMetricCard(
                    icon: "shield.righthalf.filled",
                    iconColor: .green,
                    title: "Zero Trust Tunnels",
                    value: "\(viewModel.tunnels.count)",
                    subtitle: "\(viewModel.healthyTunnelsCount) Healthy Connectors",
                    badge: "Cloudflared"
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
                .foregroundColor(.secondary)
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
                    .foregroundColor(.secondary)
                
                Spacer()
                
                NavigationLink(destination: ZonesListView()) {
                    Text("See All (\(viewModel.zones.count))")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 4)
            
            if viewModel.zones.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("No domain zones loaded")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(14)
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
                                        .foregroundColor(.primary)
                                    
                                    if let plan = zone.plan?.name {
                                        Text(plan)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(Color(UIColor.tertiaryLabel))
                            }
                            .padding(14)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
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
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cloudflare Operational Status")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text("CDN, DNS, WAF and Global Edge Centers")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("View")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(14)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(14)
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
                    .foregroundColor(iconColor)
                    .frame(width: 28, height: 28)
                    .background(iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Spacer()
                
                Text(badge)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(4)
            }
            
            Text(value)
                .font(.system(size: 26, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 125, alignment: .topLeading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
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
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(width: 78)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
