import SwiftUI

struct WorkersListView: View {
    let accountId: String
    @StateObject private var viewModel: WorkersViewModel
    @State private var showingCreateWorkerSheet = false
    @State private var showingCreatePagesSheet = false
    @State private var workerToDelete: WorkerScript?
    @State private var showingDeleteWorkerAlert = false
    @State private var pagesProjectToDelete: PagesProject?
    @State private var showingDeletePagesAlert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: WorkersViewModel(accountId: accountId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Type", selection: $viewModel.selectedSegment) {
                Text(viewModel.hasFetchedData ? "Workers (\(viewModel.workers.count))" : "Workers").tag(0)
                Text(viewModel.hasFetchedData ? "Pages (\(viewModel.pages.count))" : "Pages").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            
            contentView
                .centerConstrainedWidth(maxWidth: 840)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Workers & Pages")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: viewModel.selectedSegment == 0 ? "Search Workers" : "Search Pages")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if viewModel.selectedSegment == 0 {
                        showingCreateWorkerSheet = true
                    } else {
                        showingCreatePagesSheet = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create Worker or Project")
            }
        }
        .sheet(isPresented: $showingCreateWorkerSheet) {
            WorkerCreateSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingCreatePagesSheet) {
            PagesCreateProjectSheetView(viewModel: viewModel)
        }
        .confirmationDialog("Delete Worker", isPresented: $showingDeleteWorkerAlert, titleVisibility: .visible, presenting: workerToDelete) { worker in
            Button("Delete '\(worker.id)'", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteWorker(name: worker.id)
                        ToastManager.shared.showSuccess("Worker Deleted", message: "\(worker.id) removed.")
                    } catch {
                        ToastManager.shared.showError("Failed to delete worker", message: error.localizedDescription)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { worker in
            Text("Are you sure you want to permanently delete Worker '\(worker.id)'? Associated routes and scripts will be removed.")
        }
        .confirmationDialog("Delete Pages Project", isPresented: $showingDeletePagesAlert, titleVisibility: .visible, presenting: pagesProjectToDelete) { proj in
            Button("Delete '\(proj.name)'", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deletePagesProject(name: proj.name)
                        ToastManager.shared.showSuccess("Pages Project Deleted", message: "\(proj.name) removed.")
                    } catch {
                        ToastManager.shared.showError("Failed to delete Pages project", message: error.localizedDescription)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { proj in
            Text("Are you sure you want to delete Pages project '\(proj.name)'? Deployments and hosted assets will be permanently removed.")
        }
        .refreshable { await viewModel.fetchData() }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchData()
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if viewModel.selectedSegment == 0 {
                if !viewModel.filteredWorkers.isEmpty {
                    Section {
                        ForEach(viewModel.filteredWorkers) { worker in
                            NavigationLink {
                                WorkerDetailView(accountId: accountId, worker: worker)
                            } label: {
                                WorkerRowView(worker: worker)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    workerToDelete = worker
                                    showingDeleteWorkerAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            } else {
                if !viewModel.filteredPages.isEmpty {
                    Section {
                        ForEach(viewModel.filteredPages) { page in
                            NavigationLink {
                                PagesProjectDetailView(accountId: accountId, project: page)
                            } label: {
                                pagesRow(page)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    pagesProjectToDelete = page
                                    showingDeletePagesAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.workers.isEmpty && viewModel.pages.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchData() } }
                        )
                    )
                } else if viewModel.selectedSegment == 0 {
                    if viewModel.workers.isEmpty {
                        StateOverlayView(
                            state: .empty(
                                icon: "bolt.badge.clock",
                                title: "No Workers Found",
                                message: "You haven't deployed any Cloudflare Workers scripts to this account yet.",
                                actionTitle: "Create Worker",
                                action: { showingCreateWorkerSheet = true }
                            )
                        )
                    } else if viewModel.filteredWorkers.isEmpty && !viewModel.searchText.isEmpty {
                        StateOverlayView(
                            state: .search(
                                query: viewModel.searchText,
                                clearAction: { viewModel.searchText = "" }
                            )
                        )
                    }
                } else {
                    if viewModel.pages.isEmpty {
                        StateOverlayView(
                            state: .empty(
                                icon: "doc.richtext",
                                title: "No Pages Projects Found",
                                message: "You haven't connected or deployed any Cloudflare Pages projects yet.",
                                actionTitle: "Create Pages Project",
                                action: { showingCreatePagesSheet = true }
                            )
                        )
                    } else if viewModel.filteredPages.isEmpty && !viewModel.searchText.isEmpty {
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
    
    @ViewBuilder
    private func pagesRow(_ page: PagesProject) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "doc.richtext.fill")
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(page.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                if let sub = page.subdomain {
                    Text(sub)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let branch = page.productionBranch {
                CloudnsBadge(.custom(color: .blue, text: branch, icon: "arrow.triangle.branch"), isCompact: true)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pages project \(page.name), branch \(page.productionBranch ?? "main")")
    }
}

// MARK: - Subviews

struct WorkerRowView: View {
    let worker: WorkerScript
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: "bolt.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(worker.id)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    if let mod = worker.modifiedOn {
                        Text("Modified: \(DateFormatters.formatISO8601ToDisplay(mod, style: DateFormatters.dateOnly))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let routes = worker.routes, !routes.isEmpty {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text("\(routes.count) Route\(routes.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if let usage = worker.usageModel {
                CloudnsBadge(.custom(color: .secondary, text: usage.capitalized), isCompact: true)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Worker \(worker.id), usage model \(worker.usageModel ?? "standard")")
    }
}

struct WorkerCreateSheetView: View {
    @ObservedObject var viewModel: WorkersViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var scriptName: String = ""
    @State private var code: String = """
    export default {
      async fetch(request, env, ctx) {
        return new Response("Hello Cloudflare Worker!");
      },
    };
    """
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Worker Information")) {
                    TextField("Worker Name (e.g. api-service)", text: $scriptName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("Initial Code (ES Module)")) {
                    CodeEditorView(text: $code)
                        .frame(minHeight: 180)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Create Worker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Deploy") {
                        Task {
                            isCreating = true
                            errorMessage = nil
                            do {
                                try await viewModel.createWorker(name: scriptName.trimmingCharacters(in: .whitespacesAndNewlines), code: code)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isCreating = false
                        }
                    }
                    .disabled(scriptName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                }
            }
            .toastContainer()
        }
    }
}

struct PagesCreateProjectSheetView: View {
    @ObservedObject var viewModel: WorkersViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectName: String = ""
    @State private var prodBranch: String = "main"
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Project Information"), footer: Text("Projects created via API receive a direct-upload *.pages.dev deployment endpoint.")) {
                    TextField("Project Name", text: $projectName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("Production Branch", text: $prodBranch)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Create Pages Project")
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
                                try await viewModel.createPagesProject(
                                    name: projectName.trimmingCharacters(in: .whitespacesAndNewlines),
                                    branch: prodBranch.trimmingCharacters(in: .whitespacesAndNewlines)
                                )
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isCreating = false
                        }
                    }
                    .disabled(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                }
            }
            .toastContainer()
        }
    }
}
