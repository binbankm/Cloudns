import SwiftUI

// MARK: - TunnelsListView
// Apple HIG Compliant Cloudflare Zero Trust Tunnels Overview

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
            if !viewModel.filteredTunnels.isEmpty {
                Section {
                    ForEach(viewModel.filteredTunnels) { tunnel in
                        NavigationLink(value: tunnel) {
                            TunnelRowView(tunnel: tunnel)
                        }
                        .contextMenu {
                            Button {
                                copyToClipboard(tunnel.id, toast: "Tunnel ID Copied")
                            } label: {
                                Label("Copy Tunnel ID", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                copyToClipboard(tunnel.name, toast: "Tunnel Name Copied")
                            } label: {
                                Label("Copy Tunnel Name", systemImage: "character.textbox")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Cloudflare Tunnels…",
            isEmpty: viewModel.hasFetchedData && viewModel.tunnels.isEmpty && viewModel.errorMessage == nil,
            emptyTitle: "No Tunnels Configured",
            emptyDescription: "You haven't connected any Cloudflare Zero Trust Tunnels (cloudflared) in this account yet.",
            emptyActionTitle: "Create Tunnel",
            emptyAction: { showingCreateTunnelSheet = true },
            isSearchEmpty: viewModel.hasFetchedData && !viewModel.tunnels.isEmpty && viewModel.filteredTunnels.isEmpty && !viewModel.searchText.isEmpty,
            searchQuery: viewModel.searchText,
            errorMessage: viewModel.errorMessage.map { LocalizedStringKey($0) },
            retryAction: { Task { await viewModel.fetchTunnels() } }
        )
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Tunnels"
        )
        .navigationTitle("Cloudflare Tunnels")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: CFTunnel.self) { tunnel in
            TunnelDetailView(accountId: accountId, tunnel: tunnel)
        }
        .refreshable { await viewModel.fetchTunnels() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateTunnelSheet = true
                } label: { Image(systemName: "plus") }
                .accessibilityLabel("Create Tunnel")
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingCreateTunnelSheet) {
            CreateTunnelSheetView(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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
            ListRowIcon(
                icon: "network.badge.shield.half.filled",
                color: isHealthy ? .green : .orange
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tunnel.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text("ID: \(tunnel.id)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(isHealthy ? "Healthy" : (tunnel.status?.capitalized ?? "Inactive"))
                .font(.caption2.weight(.medium))
                .foregroundStyle(isHealthy ? .green : .orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill((isHealthy ? Color.green : Color.orange).opacity(0.12)))
        }
        .padding(.vertical, 2)
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
                Section {
                    TextField("my-tunnel", text: $tunnelName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Tunnel Name")
                } footer: {
                    Text("Name your Zero Trust Cloudflare Tunnel (e.g. home-server-tunnel).")
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
                                ToastManager.shared.showSuccess("Tunnel Created", icon: "network.badge.shield.half.filled")
                                HapticManager.notification(.success)
                                dismiss()
                            } else {
                                HapticManager.notification(.error)
                            }
                            isCreating = false
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(tunnelName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}
