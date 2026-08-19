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
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(CFTunnel.placeholders) { placeholderTunnel in
                        TunnelRowView(tunnel: placeholderTunnel)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
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
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("Cloudflare Tunnels")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Tunnels")
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
