import SwiftUI

// MARK: - DeveloperHubView
// Apple HIG Compliant Compute, Storage & AI Command Center

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
            contentView
                .navigationTitle("Developer Hub")
                .navigationBarTitleDisplayMode(.large)
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
            // MARK: - Compute
            Section("Compute & Applications") {
                NavigationLink {
                    WorkersListView(accountId: accountId)
                } label: {
                    DeveloperHubRowView(
                        icon: "bolt.fill",
                        iconColor: .orange,
                        title: "Workers",
                        subtitle: "Serverless edge functions & microservices"
                    )
                }
                .disabled(!isAccountReady)
                
                NavigationLink {
                    PagesProjectsListView(accountId: accountId)
                } label: {
                    DeveloperHubRowView(
                        icon: "macwindow",
                        iconColor: .blue,
                        title: "Pages",
                        subtitle: "Static site hosting & full-stack web apps"
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
                        subtitle: "Asynchronous message queue delivery",
                        badgeText: "PAID"
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
                        subtitle: "Coordinated edge state namespaces",
                        badgeText: "PAID"
                    )
                }
                .disabled(!isAccountReady)
            }
            
            // MARK: - Storage
            Section("Storage & Databases") {
                NavigationLink {
                    R2BucketsView(accountId: accountId)
                } label: {
                    DeveloperHubRowView(
                        icon: "archivebox.fill",
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
                        icon: "cylinder.split.1x2.fill",
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
                        subtitle: "Regional database connection acceleration",
                        badgeText: "PAID"
                    )
                }
                .disabled(!isAccountReady)
            }
            
            // MARK: - Zero Trust & Connectivity
            Section("Zero Trust & Connectivity") {
                NavigationLink {
                    TunnelsListView(accountId: accountId)
                } label: {
                    DeveloperHubRowView(
                        icon: "arrow.left.arrow.right.circle.fill",
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
            Section("Account Rules & Routing") {
                NavigationLink {
                    BulkRedirectListsView(accountId: accountId)
                } label: {
                    DeveloperHubRowView(
                        icon: "arrow.turn.up.right",
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
            Section("AI & Machine Learning") {
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
            Section("Security & Verification") {
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
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.fetchOverview(isRefresh: true)
        }
    }
}

// MARK: - DeveloperHubRowView (Inlined & Cohesive)

struct DeveloperHubRowView: View {
    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    var badgeText: String? = nil
    var badgeColor: Color = .purple
    
    var body: some View {
        HStack(spacing: 12) {
            ListRowIcon(icon: icon, color: iconColor)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    if let badgeText = badgeText {
                        Text(badgeText)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(badgeColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(badgeColor.opacity(0.12)))
                    }
                }
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
