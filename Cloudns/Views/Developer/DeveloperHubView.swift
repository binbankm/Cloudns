import SwiftUI

struct DeveloperHubView: View {
    @StateObject private var viewModel = DeveloperHubViewModel()
    
    /// Safe accountId – always resolved from a validated Account object.
    /// Never passes an empty string to child views.
    private var accountId: String {
        viewModel.selectedAccount?.id ?? ""
    }
    
    private var isAccountReady: Bool {
        !(viewModel.selectedAccount?.id ?? "").isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                contentView
            }
            .navigationTitle("Developer Hub")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(NotificationCenter.default.publisher(for: .accountSwitched)) { _ in
                viewModel.resetState()
                Task { await viewModel.fetchOverview(isRefresh: true) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .localCachePurged)) { _ in
                viewModel.resetState()
                Task { await viewModel.fetchOverview(isRefresh: true) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .appWillEnterForeground)) { _ in
                if viewModel.isStale {
                    Task { await viewModel.fetchOverview(isRefresh: true) }
                }
            }
            .task {
                await viewModel.fetchOverview(isRefresh: false)
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            // Header Account Card
            Section {
                accountHeaderCard
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
                
                // MARK: - Compute
                Section(header: Text("Compute & Applications")) {
                    NavigationLink {
                        WorkersListView(accountId: accountId)
                    } label: {
                        DeveloperHubRowView(
                            icon: "bolt.fill",
                            iconColor: .orange,
                            title: "Workers & Pages",
                            subtitle: "Serverless execution & static sites"
                        )
                    }
                    .disabled(!isAccountReady)
                    
                    NavigationLink {
                        QueuesView(accountId: accountId)
                    } label: {
                        DeveloperHubRowView(
                            icon: "tray.2.fill",
                            iconColor: .purple,
                            title: "Queues",
                            subtitle: "Asynchronous message queue delivery"
                        )
                    }
                    .disabled(!isAccountReady)
                    
                    NavigationLink {
                        DurableObjectsView(accountId: accountId)
                    } label: {
                        DeveloperHubRowView(
                            icon: "cube.fill",
                            iconColor: .cyan,
                            title: "Durable Objects",
                            subtitle: "Coordinated edge state namespaces"
                        )
                    }
                    .disabled(!isAccountReady)
                }
                
                // MARK: - Storage
                Section(header: Text("Storage & Databases")) {
                    NavigationLink {
                        R2BucketsView(accountId: accountId)
                    } label: {
                        DeveloperHubRowView(
                            icon: "externaldrive.fill",
                            iconColor: .blue,
                            title: "R2 Object Storage",
                            subtitle: "Zero egress fee S3-compatible storage"
                        )
                    }
                    .disabled(!isAccountReady)
                    
                    NavigationLink {
                        KVBrowserView(accountId: accountId)
                    } label: {
                        DeveloperHubRowView(
                            icon: "key.fill",
                            iconColor: .purple,
                            title: "KV & D1 Databases",
                            subtitle: "Global low-latency key-value & SQL"
                        )
                    }
                    .disabled(!isAccountReady)
                    
                    NavigationLink {
                        HyperdriveView(accountId: accountId)
                    } label: {
                        DeveloperHubRowView(
                            icon: "bolt.horizontal.fill",
                            iconColor: .yellow,
                            title: "Hyperdrive",
                            subtitle: "Regional database connection acceleration"
                        )
                    }
                    .disabled(!isAccountReady)
                }
                
                // MARK: - Zero Trust & Connectivity
                Section(header: Text("Zero Trust & Connectivity")) {
                    NavigationLink {
                        TunnelsListView(accountId: accountId)
                    } label: {
                        DeveloperHubRowView(
                            icon: "network",
                            iconColor: .green,
                            title: "Cloudflare Tunnels",
                            subtitle: "Secure internal server ingress"
                        )
                    }
                    .disabled(!isAccountReady)
                    
                    NavigationLink {
                        AccessAppsView(accountId: accountId)
                    } label: {
                        DeveloperHubRowView(
                            icon: "lock.shield.fill",
                            iconColor: .blue,
                            title: "Access Applications",
                            subtitle: "Zero Trust identity & security policies"
                        )
                    }
                    .disabled(!isAccountReady)
                    
                    NavigationLink {
                        GatewayRulesView(accountId: accountId)
                    } label: {
                        DeveloperHubRowView(
                            icon: "shield.lefthalf.filled",
                            iconColor: .teal,
                            title: "Gateway Rules",
                            subtitle: "DNS, HTTP & Network firewall policies"
                        )
                    }
                    .disabled(!isAccountReady)
                }
                
                // MARK: - Account Rules & Bulk Redirects
                Section(header: Text("Account Rules & Routing")) {
                    NavigationLink {
                        BulkRedirectListsView(accountId: accountId)
                    } label: {
                        DeveloperHubRowView(
                            icon: "arrow.triangle.swap",
                            iconColor: .indigo,
                            title: "Bulk Redirects",
                            subtitle: "High-volume URL redirects at account level"
                        )
                    }
                    .disabled(!isAccountReady)
                    
                    NavigationLink {
                        AlertingView(accountId: accountId)
                    } label: {
                        DeveloperHubRowView(
                            icon: "bell.badge.fill",
                            iconColor: .red,
                            title: "Notification Alerts",
                            subtitle: "Incident policies & webhook destinations"
                        )
                    }
                    .disabled(!isAccountReady)
                }
                
                // MARK: - AI Platform
                Section(header: Text("AI & Machine Learning")) {
                    NavigationLink {
                        WorkersAIView(accountId: accountId)
                    } label: {
                        DeveloperHubRowView(
                            icon: "sparkles",
                            iconColor: .purple,
                            title: "Workers AI",
                            subtitle: "Serverless LLM & vision model inference"
                        )
                    }
                    .disabled(!isAccountReady)
                    
                    NavigationLink {
                        AIGatewayView(accountId: accountId)
                    } label: {
                        DeveloperHubRowView(
                            icon: "brain.head.profile",
                            iconColor: .pink,
                            title: "AI Gateway",
                            subtitle: "Observability, rate limiting & caching"
                        )
                    }
                    .disabled(!isAccountReady)
                }
                
                // MARK: - Security & Verification
                Section(header: Text("Security & Verification")) {
                    NavigationLink {
                        TurnstileWidgetsView(accountId: accountId)
                    } label: {
                        DeveloperHubRowView(
                            icon: "checkmark.shield.fill",
                            iconColor: .blue,
                            title: "Turnstile Captcha",
                            subtitle: "Smart bot detection without puzzles"
                        )
                    }
                    .disabled(!isAccountReady)
                }
                
                // MARK: - Dev Diagnostics (Option A: Consolidated)
                Section(header: Text("Diagnostics & Tools")) {
                    NavigationLink {
                        NetworkDiagnosticsListView()
                    } label: {
                        DeveloperHubRowView(
                            icon: "wrench.and.screwdriver.fill",
                            iconColor: .indigo,
                            title: "Network & Security Diagnostics",
                            subtitle: "Trace · DNS Dig · HTTP · SSL · WHOIS · IP"
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .centerConstrainedWidth(maxWidth: 840)
            .refreshable {
                HapticManager.impact(.light)
                await viewModel.fetchOverview(isRefresh: true)
            }
        }
    
    // MARK: - Account Header Card
    
    private var accountHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Developer Suite")
                        .font(.title2.weight(.bold))
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
            .skeletonLoading(!viewModel.hasFetchedData)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.45, blue: 0.95), Color(red: 0.08, green: 0.30, blue: 0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .shadow(color: Color.blue.opacity(0.25), radius: 10, x: 0, y: 4)
    }
    
    private func metricItem(title: LocalizedStringKey, value: String) -> some View {
        VStack(spacing: 2) {
            CloudnsRollingNumber(value: value, font: .headline, weight: .bold, color: .white)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}
