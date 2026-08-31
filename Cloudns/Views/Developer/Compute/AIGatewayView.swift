import SwiftUI

// MARK: - AIGatewayView

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
            if !viewModel.filteredGateways.isEmpty {
                Section(header: Text("Configured Gateways (\(viewModel.gateways.count))"), footer: Text("AI Gateway provides observability, caching, rate limiting, and fallback for OpenAI, Anthropic, Workers AI, and more.")) {
                    ForEach(viewModel.filteredGateways) { gw in
                        NavigationLink(destination: AIGatewayDetailView(accountId: viewModel.accountId, gateway: gw)) {
                            gatewayRow(gw)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
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
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Gateways"
        )
        .navigationTitle("AI Gateway")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
             .higToast()
        }
        .confirmationDialog("Delete AI Gateway", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: gatewayToDelete) { gw in
            Button("Delete '\(gw.name ?? gw.id)'", role: .destructive) {
                HIGFeedback.impact(.medium)
                Task {
                    do {
                        try await viewModel.deleteGateway(id: gw.id)
                        HIGFeedback.success()
                    } catch {
                        HIGFeedback.error()
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
            if !viewModel.hasFetchedData && viewModel.isLoading {
            HIGContentState(.loading(message: "Loading AI Gateways…"))
        } else if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.gateways.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchGateways() }
                            }
                        )
                    )
                } else if viewModel.gateways.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No AI Gateways",
                            systemImage: "brain.head.profile",
                            description: "Create an AI Gateway to observe, cache, and manage your AI API traffic.",
                            actionTitle: "Create Gateway",
                            action: { showingCreateSheet = true }
                        )
                    )
                } else if viewModel.filteredGateways.isEmpty && !viewModel.searchText.isEmpty {
                    HIGContentState(.search(query: viewModel.searchText))
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
        HStack(spacing: 12) {
            ListRowIcon(icon: "brain.head.profile", color: .pink, size: 32, cornerRadius: 8)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(gw.name ?? gw.id)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text(gw.id)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if gw.collectLogs == true {
                HIGBadge(.active, isCompact: true)
            }
        }
        .padding(.vertical, 3)
    }
}

// MARK: - AIGatewayCreateSheetView (Inlined & Cohesive)

struct AIGatewayCreateSheetView: View {
    @ObservedObject var viewModel: AIGatewaysViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var gatewayId = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Gateway ID"), footer: Text("Unique identifier using letters, numbers, and hyphens (e.g. my-ai-gateway).")) {
                    TextField("my-ai-gateway", text: $gatewayId)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                if let err = errorMessage {
                    Section {
                        Text(verbatim: err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New AI Gateway")
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
                            errorMessage = nil
                            do {
                                try await viewModel.createGateway(id: gatewayId.trimmingCharacters(in: .whitespaces))
                                HIGFeedback.success()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
                            }
                            isCreating = false
                        }
                    }
                    .disabled(gatewayId.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}
