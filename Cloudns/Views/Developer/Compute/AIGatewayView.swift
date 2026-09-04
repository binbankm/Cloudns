import SwiftUI

// MARK: - AIGatewayView
// Apple HIG Compliant Cloudflare AI Gateway Catalog & Lifecycle Management

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
                        .contextMenu {
                            Button {
                                copyToClipboard(gw.id, toast: "Gateway ID Copied")
                            } label: {
                                Label("Copy Gateway ID", systemImage: "doc.on.doc")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                gatewayToDelete = gw
                                showingDeleteAlert = true
                                HapticManager.impact(.medium)
                            } label: {
                                Label("Delete Gateway", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                gatewayToDelete = gw
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
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
        }
        .confirmationDialog("Delete AI Gateway", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: gatewayToDelete) { gw in
            Button("Delete '\(gw.name ?? gw.id)'", role: .destructive) {
                HapticManager.impact(.medium)
                Task {
                    do {
                        try await viewModel.deleteGateway(id: gw.id)
                        ToastManager.shared.showSuccess("Gateway Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                    } catch {
                        ToastManager.shared.showError("Failed to Delete Gateway")
                        HapticManager.notification(.error)
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
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading AI Gateways…",
            isEmpty: viewModel.hasFetchedData && viewModel.gateways.isEmpty,
            emptyTitle: "No AI Gateways",
            emptySystemImage: "brain.head.profile",
            emptyDescription: "Create an AI Gateway to observe, cache, and manage your AI API traffic.",
            emptyActionTitle: "Create Gateway",
            emptyAction: { showingCreateSheet = true },
            isSearchEmpty: viewModel.hasFetchedData && viewModel.filteredGateways.isEmpty && !viewModel.searchText.isEmpty,
            searchQuery: viewModel.searchText,
            errorMessage: (viewModel.hasFetchedData && viewModel.gateways.isEmpty) ? viewModel.errorMessage.map { LocalizedStringKey($0) } : nil,
            retryAction: { Task { await viewModel.fetchGateways() } }
        )
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchGateways()
            }
        }
    }
    
    @ViewBuilder
    private func gatewayRow(_ gw: AIGateway) -> some View {
        HStack(spacing: 12) {
            ListRowIcon(icon: "brain.head.profile", color: .pink)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(gw.name ?? gw.id)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text(gw.id)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if gw.collectLogs == true {
                Text("Active")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.green.opacity(0.12)))
            }
        }
        .padding(.vertical, 2)
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
                        .font(.body.monospaced())
                }
                
                if let err = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(verbatim: err)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Create Gateway")
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
                                ToastManager.shared.showSuccess("Gateway Created", icon: "brain.head.profile")
                                HapticManager.notification(.success)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.notification(.error)
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
