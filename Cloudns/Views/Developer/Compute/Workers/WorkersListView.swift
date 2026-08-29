import SwiftUI

// MARK: - WorkersListView (Pure List - No Tags)

struct WorkersListView: View {
    let accountId: String
    @StateObject private var viewModel: WorkersViewModel
    @State private var showingCreateWorkerSheet = false
    @State private var workerToDelete: WorkerScript?
    @State private var showingDeleteWorkerAlert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: WorkersViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(WorkerScript.placeholders) { (script: WorkerScript) in
                        WorkerRowView(worker: script)
                    }
                }
                .redacted(reason: .placeholder)
            } else if !viewModel.filteredWorkers.isEmpty {
                Section(header: Text("Workers Scripts (\(viewModel.filteredWorkers.count))")) {
                    ForEach(viewModel.filteredWorkers) { worker in
                        NavigationLink {
                            WorkerDetailView(accountId: accountId, worker: worker)
                        } label: {
                            WorkerRowView(worker: worker)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                workerToDelete = worker
                                showingDeleteWorkerAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.workers.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchData() } }
                        )
                    )
                } else if viewModel.workers.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Workers Found",
                            systemImage: "bolt.badge.clock",
                            description: "You haven't deployed any Cloudflare Workers scripts to this account yet.",
                            actionTitle: "Create Worker",
                            action: { showingCreateWorkerSheet = true }
                        )
                    )
                } else if viewModel.filteredWorkers.isEmpty && !viewModel.searchText.isEmpty {
                    HIGContentState(.search(query: viewModel.searchText))
                }
            }
        }
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search Workers"
        )
        .navigationTitle("Workers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateWorkerSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create Worker")
            }
        }
        .sheet(isPresented: $showingCreateWorkerSheet) {
            WorkerCreateSheetView(viewModel: viewModel)
             .higToast()
        }
        .confirmationDialog("Delete Worker", isPresented: $showingDeleteWorkerAlert, titleVisibility: .visible, presenting: workerToDelete) { worker in
            Button("Delete '\(worker.id)'", role: .destructive) {
                Task {
                    await viewModel.deleteWorker(name: worker.id)
                    HIGFeedback.success()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { worker in
            Text("Are you sure you want to permanently delete Worker '\(worker.id)'? Associated routes and scripts will be removed.")
        }
        .refreshable { await viewModel.fetchData() }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchData()
            }
        }
    }
}

// MARK: - WorkerRowView (Inlined & Cohesive)

struct WorkerRowView: View {
    let worker: WorkerScript
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "bolt.fill")
                .font(.body)
                .foregroundStyle(.orange)
                .frame(width: 32, height: 32)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(worker.id)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let modified = worker.modifiedOn {
                    Text("Updated \(DateFormatters.formatISO8601ToDisplay(modified, style: DateFormatters.dateOnly))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            HIGBadge(.active, isCompact: true)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - WorkerCreateSheetView (Inlined & Cohesive)

struct WorkerCreateSheetView: View {
    @ObservedObject var viewModel: WorkersViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    private let templateCode = """
    export default {
      async fetch(request, env, ctx) {
        return new Response("Hello World from Cloudflare Workers!");
      }
    };
    """
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Worker Script Name"), footer: Text("Unique script identifier (e.g. auth-middleware).")) {
                    TextField("my-worker", text: $name)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Worker")
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
                                try await viewModel.createWorker(name: name.trimmingCharacters(in: .whitespaces), code: templateCode)
                                HIGFeedback.success()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
                            }
                            isCreating = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}
