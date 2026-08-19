import SwiftUI

struct AIGatewayView: View {
    let accountId: String
    @StateObject private var viewModel: AIGatewaysViewModel
    @State private var showingCreateSheet = false
    @State private var gatewayToDelete: AIGateway?
    @State private var showingDeleteAlert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: AIGatewaysViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section(header: Text("Configured Gateways")) {
                    ForEach(AIGateway.placeholders) { placeholder in
                        gatewayRow(placeholder)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
            } else if !viewModel.filteredGateways.isEmpty {
                Section(header: Text("Configured Gateways (\(viewModel.gateways.count))"), footer: Text("AI Gateway provides observability, caching, rate limiting, and fallback for OpenAI, Anthropic, Workers AI, and more.")) {
                    ForEach(viewModel.filteredGateways) { gw in
                        NavigationLink(destination: AIGatewayDetailView(accountId: viewModel.accountId, gateway: gw)) {
                            gatewayRow(gw)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                gatewayToDelete = gw
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("AI Gateway")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Gateways")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create AI Gateway")
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            AIGatewayCreateSheetView(viewModel: viewModel)
        }
        .confirmationDialog("Delete AI Gateway", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: gatewayToDelete) { gw in
            Button("Delete '\(gw.name ?? gw.id)'", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteGateway(id: gw.id)
                        ToastManager.shared.showSuccess("Gateway Deleted", message: gw.id)
                    } catch {
                        ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { gw in
            Text("Are you sure you want to delete AI Gateway '\(gw.name ?? gw.id)'? Real-time logs and cached request data will be deleted.")
        }
        .refreshable {
            await viewModel.fetchGateways()
        }
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.gateways.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchGateways() }
                            }
                        )
                    )
                } else if viewModel.gateways.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "brain.head.profile",
                            title: "No AI Gateways",
                            message: "Create an AI Gateway to observe, cache, and manage your AI API traffic.",
                            actionTitle: "Create Gateway",
                            action: { showingCreateSheet = true }
                        )
                    )
                } else if viewModel.filteredGateways.isEmpty && !viewModel.searchText.isEmpty {
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
                await viewModel.fetchGateways()
            }
        }
    }
    
    @ViewBuilder
    private func gatewayRow(_ gw: AIGateway) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "brain.head.profile")
                .font(.body)
                .foregroundStyle(.pink)
                .frame(width: 32, height: 32)
                .background(Color.pink.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(gw.id)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    if gw.collectLogs == true {
                        CloudnsBadge(.active("Logs Active"), isCompact: true)
                    }

                    if let created = gw.createdOn {
                        Text("Created: \(DateFormatters.formatISO8601ToDisplay(created, style: DateFormatters.dateOnly))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 3)
    }
}
