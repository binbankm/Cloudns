import SwiftUI

// MARK: - WorkersListView (Pure List - No Tags)
// Apple HIG Compliant Cloudflare Workers Overview

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
            if !viewModel.filteredWorkers.isEmpty {
                Section(header: Text("Workers Scripts (\(viewModel.filteredWorkers.count))")) {
                    ForEach(viewModel.filteredWorkers) { worker in
                        NavigationLink(value: worker) {
                            WorkerRowView(worker: worker)
                        }
                        .contextMenu {
                            Button {
                                copyToClipboard(worker.id, toast: "Worker Name Copied")
                            } label: {
                                Label("Copy Name", systemImage: "doc.on.doc")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                workerToDelete = worker
                                showingDeleteWorkerAlert = true
                            } label: {
                                Label("Delete Worker", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                workerToDelete = worker
                                showingDeleteWorkerAlert = true
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
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Workers…",
            isEmpty: viewModel.hasFetchedData && viewModel.workers.isEmpty,
            emptyTitle: "No Workers Found",
            emptySystemImage: "bolt.badge.clock",
            emptyDescription: "You haven't deployed any Cloudflare Workers scripts to this account yet.",
            emptyActionTitle: "Create Worker",
            emptyAction: { showingCreateWorkerSheet = true },
            isSearchEmpty: viewModel.hasFetchedData && viewModel.filteredWorkers.isEmpty && !viewModel.searchText.isEmpty,
            searchQuery: viewModel.searchText,
            errorMessage: (viewModel.hasFetchedData && viewModel.workers.isEmpty) ? viewModel.errorMessage.map { LocalizedStringKey($0) } : nil,
            retryAction: { Task { await viewModel.fetchData() } }
        )
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Workers"
        )
        .navigationTitle("Workers")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: WorkerScript.self) { worker in
            WorkerDetailView(accountId: accountId, worker: worker)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateWorkerSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create Worker")
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingCreateWorkerSheet) {
            WorkerCreateSheetView(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Delete Worker", isPresented: $showingDeleteWorkerAlert, titleVisibility: .visible, presenting: workerToDelete) { worker in
            Button("Delete '\(worker.id)'", role: .destructive) {
                Task {
                    await viewModel.deleteWorker(name: worker.id)
                    ToastManager.shared.showSuccess("Worker Deleted", icon: "trash.fill")
                    HapticManager.notification(.success)
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
        HStack(alignment: .center, spacing: 12) {
            ListRowIcon(icon: "bolt.fill", color: .accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(worker.id)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let modified = worker.modifiedOn, let date = DateFormatters.parseISO8601(modified) {
                    Text("Updated \(date.displayFormatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text("Active")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.green)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.green.opacity(0.12)))
        }
        .padding(.vertical, 2)
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
                        Text(verbatim: err)
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
                                ToastManager.shared.showSuccess("Worker Created", icon: "bolt.fill")
                                HapticManager.notification(.success)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.notification(.error)
                            }
                            isCreating = false
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}
