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
                        NavigationLink {
                            TunnelDetailView(accountId: accountId, tunnel: tunnel)
                        } label: {
                            TunnelRowView(tunnel: tunnel)
                        }
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = tunnel.id
                                ToastManager.shared.showCopied("Tunnel ID Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy Tunnel ID", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                UIPasteboard.general.string = tunnel.name
                                ToastManager.shared.showCopied("Tunnel Name Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy Tunnel Name", systemImage: "character.textbox")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
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
                .higTouchTarget()
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingCreateTunnelSheet) {
            CreateTunnelSheetView(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .higToast()
        }
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Cloudflare Tunnels…"))
            } else if viewModel.hasFetchedData {
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
        HStack(spacing: HIGTokens.Spacing.md) {
            ListRowIcon(
                icon: "network.badge.shield.half.filled",
                color: isHealthy ? HIGColors.success : HIGColors.warning
            )
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text(tunnel.name)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text("ID: \(tunnel.id)")
                    .font(HIGTypography.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HIGBadge(isHealthy ? .active : .warning(tunnel.status?.capitalized ?? "Inactive"), isCompact: true)
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
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
                                ToastManager.shared.showSuccess("Tunnel Created", icon: "network.badge.shield.half.filled")
                                HIGFeedback.success()
                                dismiss()
                            } else {
                                HIGFeedback.error()
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
