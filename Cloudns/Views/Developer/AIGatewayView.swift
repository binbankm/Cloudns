import SwiftUI

struct AIGatewayView: View {
    let accountId: String
    @StateObject private var viewModel: AIGatewaysViewModel
    @State private var showingCreateSheet = false
    @State private var gatewayToDelete: AIGateway? = nil
    @State private var showingDeleteAlert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: AIGatewaysViewModel(accountId: accountId))
    }
    
    var body: some View {
        contentView
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
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                AIGatewayCreateSheetView(viewModel: viewModel)
            }
            .alert("Delete AI Gateway", isPresented: $showingDeleteAlert, presenting: gatewayToDelete) { gw in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteGateway(id: gw.id)
                            ToastManager.shared.showSuccess("Gateway Deleted", message: gw.id)
                        } catch {
                            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                        }
                    }
                }
            } message: { gw in
                Text("Are you sure you want to delete AI Gateway '\(gw.id)'? Endpoint URLs and logged metrics will no longer be available.")
            }
            .refreshable {
                await viewModel.fetchGateways()
            }
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchGateways()
                }
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)

            if viewModel.isLoading && !viewModel.hasFetchedData {
                List {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
                .listStyle(.insetGrouped)
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                EmptyStateView.error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task { await viewModel.fetchGateways() }
                    }
                )
            } else if viewModel.gateways.isEmpty {
                EmptyStateView(
                    icon: "brain.head.profile",
                    title: "No AI Gateways",
                    message: "Create an AI Gateway to observe, cache, and manage your AI API traffic.",
                    actionTitle: "Create Gateway",
                    action: { showingCreateSheet = true }
                )
            } else if viewModel.filteredGateways.isEmpty {
                EmptyStateView.search(query: viewModel.searchText) {
                    viewModel.searchText = ""
                }
            } else {
                List {
                    Section(header: Text("Configured Gateways (\(viewModel.gateways.count))"), footer: Text("AI Gateway provides observability, caching, rate limiting, and fallback for OpenAI, Anthropic, Workers AI, and more.")) {
                        ForEach(viewModel.filteredGateways) { gw in
                            HStack(alignment: .center, spacing: 14) {
                                Image(systemName: "brain.head.profile")
                                    .font(.body)
                                    .foregroundColor(.pink)
                                    .frame(width: 32, height: 32)
                                    .background(Color.pink.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(gw.id)
                                        .font(.body.monospacedDigit())
                                        .foregroundColor(.primary)

                                    HStack(spacing: 8) {
                                        if gw.collectLogs == true {
                                            Label("Logs Active", systemImage: "checkmark.circle.fill")
                                                .font(.caption2)
                                                .foregroundColor(.green)
                                        }

                                        if let created = gw.createdOn {
                                            Text("Created: \(String(created.prefix(10)))")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }

                                Spacer()
                            }
                            .padding(.vertical, 3)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    gatewayToDelete = gw
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = "https://gateway.ai.cloudflare.com/v1/\(viewModel.accountId)/\(gw.id)"
                                    ToastManager.shared.showCopied("Gateway URL copied")
                                } label: {
                                    Label("Copy Gateway URL", systemImage: "link")
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

struct AIGatewayCreateSheetView: View {
    @ObservedObject var viewModel: AIGatewaysViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var gatewayId = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Gateway ID"), footer: Text("A unique slug used in the Gateway universal endpoint URL.")) {
                    TextField("my-ai-gateway", text: $gatewayId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New AI Gateway")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            errorMessage = nil
                            do {
                                try await viewModel.createGateway(id: gatewayId.trimmingCharacters(in: .whitespaces))
                                ToastManager.shared.showSuccess("AI Gateway", message: "Gateway created successfully")
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isCreating = false
                        }
                    }
                    .disabled(gatewayId.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .toastContainer()
        }
    }
}
