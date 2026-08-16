import SwiftUI

struct DeveloperHubView: View {
    @StateObject private var viewModel = DeveloperHubViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                
                contentView
            }
            .navigationTitle("Developer Hub")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.fetchOverview(isRefresh: true)
            }
            .task {
                await viewModel.fetchOverview(isRefresh: false)
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section {
                    accountHeaderCard
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                ForEach(0..<4, id: \.self) { _ in
                    Section {
                        SkeletonRowView()
                        SkeletonRowView()
                    }
                }
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                Section {
                    EmptyStateView.error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task {
                                await viewModel.fetchOverview(isRefresh: true)
                            }
                        }
                    )
                }
                .listRowBackground(Color.clear)
            } else {
                // Header Account Card
                Section {
                    accountHeaderCard
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                // Section: Compute
                Section(header: Text("Compute & Applications")) {
                    NavigationLink {
                        WorkersListView(accountId: viewModel.selectedAccount?.id ?? "")
                    } label: {
                        DeveloperHubRow(
                            icon: "bolt.fill",
                            iconColor: .orange,
                            title: "Workers & Pages",
                            subtitle: "Serverless execution & static sites",
                            badgeText: "\(viewModel.workers.count + viewModel.pagesProjects.count)"
                        )
                    }
                    
                    NavigationLink {
                        QueuesView(accountId: viewModel.selectedAccount?.id ?? "")
                    } label: {
                        DeveloperHubRow(
                            icon: "tray.2.fill",
                            iconColor: .purple,
                            title: "Queues",
                            subtitle: "Asynchronous message queue delivery",
                            badgeText: "Queue"
                        )
                    }
                    
                    NavigationLink {
                        DurableObjectsView(accountId: viewModel.selectedAccount?.id ?? "")
                    } label: {
                        DeveloperHubRow(
                            icon: "cube.fill",
                            iconColor: .cyan,
                            title: "Durable Objects",
                            subtitle: "Coordinated edge state namespaces",
                            badgeText: "DO"
                        )
                    }
                }
                
                // Section: Storage
                Section(header: Text("Storage & Databases")) {
                    NavigationLink {
                        R2BucketsView(accountId: viewModel.selectedAccount?.id ?? "")
                    } label: {
                        DeveloperHubRow(
                            icon: "externaldrive.fill",
                            iconColor: .blue,
                            title: "R2 Object Storage",
                            subtitle: "Zero egress fee S3-compatible storage",
                            badgeText: "\(viewModel.r2Buckets.count) Buckets"
                        )
                    }
                    
                    NavigationLink {
                        KVBrowserView(accountId: viewModel.selectedAccount?.id ?? "")
                    } label: {
                        DeveloperHubRow(
                            icon: "key.fill",
                            iconColor: .purple,
                            title: "KV & D1 Databases",
                            subtitle: "Global low-latency key-value & SQL",
                            badgeText: "\(viewModel.kvNamespaces.count) KV"
                        )
                    }
                    
                    NavigationLink {
                        HyperdriveView(accountId: viewModel.selectedAccount?.id ?? "")
                    } label: {
                        DeveloperHubRow(
                            icon: "bolt.horizontal.fill",
                            iconColor: .yellow,
                            title: "Hyperdrive",
                            subtitle: "Regional database connection acceleration",
                            badgeText: "Fast"
                        )
                    }
                }
                
                // Section: Zero Trust & Connectivity
                Section(header: Text("Zero Trust & Connectivity")) {
                    NavigationLink {
                        TunnelsListView(accountId: viewModel.selectedAccount?.id ?? "")
                    } label: {
                        DeveloperHubRow(
                            icon: "network",
                            iconColor: .green,
                            title: "Cloudflare Tunnels",
                            subtitle: "Secure internal server ingress",
                            badgeText: "\(viewModel.tunnels.count) Active",
                            isStatusBadge: true,
                            isHealthy: viewModel.activeTunnelCount > 0
                        )
                    }
                    
                    NavigationLink {
                        AccessAppsView(accountId: viewModel.selectedAccount?.id ?? "")
                    } label: {
                        DeveloperHubRow(
                            icon: "lock.shield.fill",
                            iconColor: .blue,
                            title: "Access Applications",
                            subtitle: "Zero Trust identity & security policies",
                            badgeText: "Access"
                        )
                    }
                    
                    NavigationLink {
                        GatewayRulesView(accountId: viewModel.selectedAccount?.id ?? "")
                    } label: {
                        DeveloperHubRow(
                            icon: "shield.lefthalf.filled",
                            iconColor: .teal,
                            title: "Gateway Rules",
                            subtitle: "DNS, HTTP & Network firewall policies",
                            badgeText: "Gateway"
                        )
                    }
                }
                
                // Section: Account Rules & Bulk Redirects
                Section(header: Text("Account Rules & Routing")) {
                    NavigationLink {
                        BulkRedirectListsView(accountId: viewModel.selectedAccount?.id ?? "")
                    } label: {
                        DeveloperHubRow(
                            icon: "arrow.triangle.swap",
                            iconColor: .indigo,
                            title: "Bulk Redirects",
                            subtitle: "High-volume URL redirects at account level",
                            badgeText: "Redirects"
                        )
                    }
                    
                    NavigationLink {
                        AlertingView(accountId: viewModel.selectedAccount?.id ?? "")
                    } label: {
                        DeveloperHubRow(
                            icon: "bell.badge.fill",
                            iconColor: .red,
                            title: "Notification Alerts",
                            subtitle: "Incident policies & webhook destinations",
                            badgeText: "Alerts"
                        )
                    }
                }
                
                // Section: AI Platform
                Section(header: Text("AI & Machine Learning")) {
                    NavigationLink {
                        WorkersAIView(accountId: viewModel.selectedAccount?.id ?? "")
                    } label: {
                        DeveloperHubRow(
                            icon: "sparkles",
                            iconColor: .purple,
                            title: "Workers AI",
                            subtitle: "Serverless LLM & vision model inference",
                            badgeText: "AI"
                        )
                    }
                    
                    NavigationLink {
                        AIGatewayView(accountId: viewModel.selectedAccount?.id ?? "")
                    } label: {
                        DeveloperHubRow(
                            icon: "brain.head.profile",
                            iconColor: .pink,
                            title: "AI Gateway",
                            subtitle: "Observability, rate limiting & caching",
                            badgeText: "Gateway"
                        )
                    }
                }
                
                // Section: Security & Verification
                Section(header: Text("Security & Verification")) {
                    NavigationLink {
                        TurnstileWidgetsView(accountId: viewModel.selectedAccount?.id ?? "")
                    } label: {
                        DeveloperHubRow(
                            icon: "checkmark.shield.fill",
                            iconColor: .blue,
                            title: "Turnstile Captcha",
                            subtitle: "Smart bot detection without puzzles",
                            badgeText: "Turnstile"
                        )
                    }
                }
                
                // Section: Dev Diagnostics (Option A: Consolidated)
                Section(header: Text("Diagnostics & Tools")) {
                    NavigationLink {
                        NetworkDiagnosticsListView()
                    } label: {
                        DeveloperHubRow(
                            icon: "wrench.and.screwdriver.fill",
                            iconColor: .indigo,
                            title: "Network & Security Diagnostics",
                            subtitle: "Trace · DNS Dig · HTTP · SSL · WHOIS · IP",
                            badgeText: "7 Tools"
                        )
                    }
                }
                
                // Section: Account Activity
                Section(header: Text("Account Activity")) {
                    NavigationLink {
                        AuditLogsView(accountId: viewModel.selectedAccount?.id ?? "")
                    } label: {
                        DeveloperHubRow(
                            icon: "list.clipboard.fill",
                            iconColor: .purple,
                            title: "Audit Logs",
                            subtitle: "Recent account modifications & actions",
                            badgeText: "Logs"
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Account Header Card
    
    private var accountHeaderCard: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.45, blue: 0.95), Color(red: 0.08, green: 0.30, blue: 0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Developer Suite")
                            .font(.title2)
                            .foregroundStyle(.white)
                        
                        Text(viewModel.selectedAccount?.name ?? "Active Account")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.85))
                        .accessibilityHidden(true)
                }
                
                Divider()
                    .overlay(Color.white.opacity(0.25))
                
                // Metrics grid
                HStack(spacing: 12) {
                    metricItem(title: "Workers", value: "\(viewModel.workers.count)")
                    metricItem(title: "Pages", value: "\(viewModel.pagesProjects.count)")
                    metricItem(title: "R2", value: "\(viewModel.r2Buckets.count)")
                    metricItem(title: "Tunnels", value: "\(viewModel.tunnels.count)")
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private func metricItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.body)
                .foregroundStyle(.white)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Row Component (Strictly conforming to ZoneNavRow)

struct DeveloperHubRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var badgeText: String? = nil
    var isStatusBadge: Bool = false
    var isHealthy: Bool = true
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Text(LocalizedStringKey(subtitle))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let badge = badgeText {
                if isStatusBadge {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(isHealthy ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)
                        Text(badge)
                            .font(.caption)
                            .foregroundStyle(isHealthy ? .green : .orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isHealthy ? Color.green : Color.orange).opacity(0.12))
                    .cornerRadius(8)
                } else {
                    Text(badge)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.12))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 3)
    }
}
