import SwiftUI

struct TunnelsListView: View {
    let accountId: String
    @StateObject private var viewModel: TunnelsViewModel
    @State private var showingCreateTunnelSheet = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: TunnelsViewModel(accountId: accountId))
    }
    
    var body: some View {
        Group {
            if !viewModel.hasFetchedData {
                // Skeleton phase — no .searchable, prevents overlap
                List {
                    Section {
                        ForEach(CFTunnel.placeholders) { tunnel in
                            TunnelRowView(tunnel: tunnel)
                        }
                    }
                    .skeletonLoading(true)
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Cloudflare Tunnels")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                // Data-ready phase — .searchable safely attached
                contentView
                    .navigationTitle("Cloudflare Tunnels")
                    .navigationBarTitleDisplayMode(.inline)
                    .searchable(text: $viewModel.searchText, prompt: "Search Tunnels")
                    .refreshable { await viewModel.fetchTunnels() }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingCreateTunnelSheet = true
                            } label: { Image(systemName: "plus") }
                            .accessibilityLabel("Create Tunnel")
                        }
                    }
                    .sheet(isPresented: $showingCreateTunnelSheet) {
                        CreateTunnelSheetView(viewModel: viewModel)
                    }
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchTunnels()
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if !viewModel.filteredTunnels.isEmpty {
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
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.tunnels.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchTunnels() }
                            }
                        )
                    )
                } else if viewModel.tunnels.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "network.badge.shield.half.filled",
                            title: "No Tunnels Configured",
                            message: "You haven't connected any Cloudflare Zero Trust Tunnels (cloudflared) in this account yet.",
                            actionTitle: "Create Tunnel",
                            action: { showingCreateTunnelSheet = true }
                        )
                    )
                } else if viewModel.filteredTunnels.isEmpty && !viewModel.searchText.isEmpty {
                    StateOverlayView(
                        state: .search(
                            query: viewModel.searchText,
                            clearAction: { viewModel.searchText = "" }
                        )
                    )
                }
            }
        }
    }
}

struct TunnelRowView: View {
    let tunnel: CFTunnel
    
    var isHealthy: Bool {
        tunnel.isHealthy
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "network")
                .font(.body)
                .foregroundStyle(isHealthy ? .green : .red)
                .frame(width: 32, height: 32)
                .background((isHealthy ? Color.green : Color.red).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(tunnel.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Text((tunnel.status ?? "Inactive").capitalized)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(isHealthy ? .green : .red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((isHealthy ? Color.green : Color.red).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                Text(tunnel.id)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if let count = tunnel.connections?.count {
                Text("\(count) Connectors")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                UIPasteboard.general.string = tunnel.id
                HapticManager.impact(.light)
                ToastManager.shared.showCopied("Tunnel ID copied")
            } label: {
                Label("Copy Tunnel UUID", systemImage: "doc.on.doc")
            }
        }
    }
}

struct CreateTunnelSheetView: View {
    @ObservedObject var viewModel: TunnelsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var tunnelName = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("Tunnel Information"),
                    footer: Text("Creates a remotely managed Cloudflare Zero Trust tunnel. Once created, install cloudflared using the generated connector token.")
                ) {
                    TextField("Tunnel Name (e.g. homelab-gateway)", text: $tunnelName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Create Tunnel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            let success = await viewModel.createTunnel(name: tunnelName.trimmingCharacters(in: .whitespaces))
                            if success { dismiss() }
                            isCreating = false
                        }
                    }
                    .disabled(tunnelName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .toastContainer()
        }
    }
}
