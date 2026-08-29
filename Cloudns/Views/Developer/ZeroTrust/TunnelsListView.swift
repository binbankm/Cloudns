import SwiftUI

// MARK: - TunnelsListView

struct TunnelsListView: View {
    let accountId: String
    @StateObject private var viewModel: TunnelsViewModel
    @State private var showingCreateTunnelSheet = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: TunnelsViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(CFTunnel.placeholders) { placeholderTunnel in
                        TunnelRowView(tunnel: placeholderTunnel)
                    }
                }
                .redacted(reason: .placeholder)
            } else if !viewModel.filteredTunnels.isEmpty {
                Section {
                    ForEach(viewModel.filteredTunnels) { tunnel in
                        NavigationLink {
                            TunnelDetailView(accountId: accountId, tunnel: tunnel)
                        } label: {
                            TunnelRowView(tunnel: tunnel)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search Tunnels"
        )
        .navigationTitle("Cloudflare Tunnels")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.fetchTunnels() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateTunnelSheet = true
                } label: { Image(systemName: "plus") }
                .accessibilityLabel("Create Tunnel")
            }
        }
        .sheet(isPresented: $showingCreateTunnelSheet) {
            CreateTunnelSheetView(viewModel: viewModel)
        }
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.tunnels.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchTunnels() }
                            }
                        )
                    )
                } else if viewModel.tunnels.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Tunnels Configured",
                            systemImage: "network.badge.shield.half.filled",
                            description: "You haven't connected any Cloudflare Zero Trust Tunnels (cloudflared) in this account yet.",
                            actionTitle: "Create Tunnel",
                            action: { showingCreateTunnelSheet = true }
                        )
                    )
                } else if viewModel.filteredTunnels.isEmpty && !viewModel.searchText.isEmpty {
                    HIGContentState(.search(query: viewModel.searchText))
                }
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchTunnels()
            }
        }
        .onAppear {
            if viewModel.hasFetchedData {
                Task { await viewModel.fetchTunnels() }
            }
        }
    }
}

// MARK: - TunnelRowView (Inlined & Cohesive)

struct TunnelRowView: View {
    let tunnel: CFTunnel
    
    private var isHealthy: Bool {
        tunnel.status?.lowercased() == "healthy"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "network.badge.shield.half.filled")
                .foregroundStyle(isHealthy ? .green : .orange)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background((isHealthy ? Color.green : Color.orange).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(tunnel.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text("ID: \(tunnel.id)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HIGBadge(isHealthy ? .active : .warning(tunnel.status?.capitalized ?? "Inactive"), isCompact: true)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - CreateTunnelSheetView (Inlined & Cohesive)

struct CreateTunnelSheetView: View {
    @ObservedObject var viewModel: TunnelsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var tunnelName = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("Tunnel Name"),
                    footer: Text("Name your Zero Trust Cloudflare Tunnel (e.g. home-server-tunnel).")
                ) {
                    TextField("my-tunnel", text: $tunnelName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Tunnel")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            let success = await viewModel.createTunnel(name: tunnelName.trimmingCharacters(in: .whitespaces))
                            if success {
                                HIGFeedback.success()
                                dismiss()
                            } else {
                                HIGFeedback.error()
                            }
                            isCreating = false
                        }
                    }
                    .disabled(tunnelName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}
