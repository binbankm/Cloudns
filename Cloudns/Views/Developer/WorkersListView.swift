import SwiftUI

struct WorkersListView: View {
    let accountId: String
    @StateObject private var viewModel: WorkersViewModel
    @State private var showingCreateWorkerSheet = false
    @State private var showingCreatePagesSheet = false
    @State private var workerToDelete: WorkerScript? = nil
    @State private var showingDeleteWorkerAlert = false
    @State private var projectToDelete: PagesProject? = nil
    @State private var showingDeletePagesAlert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: WorkersViewModel(accountId: accountId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Type", selection: $viewModel.selectedSegment) {
                Text("Workers (\(viewModel.workers.count))").tag(0)
                Text("Pages (\(viewModel.pages.count))").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGroupedBackground))
            
            contentView
        }
        .background(Color(UIColor.systemGroupedBackground))
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
                .accessibilityLabel("添加 Worker 或 Pages")
            }
        }
        .sheet(isPresented: $showingCreateWorkerSheet) {
            WorkerCreateSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingCreatePagesSheet) {
            PagesCreateProjectSheetView(viewModel: viewModel)
        }
        .alert("Delete Worker", isPresented: $showingDeleteWorkerAlert, presenting: workerToDelete) { worker in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteWorker(name: worker.id)
                        ToastManager.shared.showSuccess("Worker Deleted", message: worker.id)
                    } catch {
                        ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                    }
                }
            }
        } message: { worker in
            Text("Are you sure you want to delete Worker '\(worker.id)'? All deployed routes and scripts will be permanently removed.")
        }
        .alert("Delete Pages Project", isPresented: $showingDeletePagesAlert, presenting: projectToDelete) { proj in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deletePagesProject(name: proj.name)
                        ToastManager.shared.showSuccess("Pages Project Deleted", message: proj.name)
                    } catch {
                        ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                    }
                }
            }
        } message: { proj in
            Text("Are you sure you want to delete Pages project '\(proj.name)'? Deployments and hosted assets will be permanently removed.")
        }
        .refreshable {
            await viewModel.fetchData()
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchData()
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading && !viewModel.hasFetchedData {
                List {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
                .listStyle(.insetGrouped)
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                EmptyStateView.error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task { await viewModel.fetchData() }
                    }
                )
            } else if viewModel.selectedSegment == 0 {
                if viewModel.workers.isEmpty {
                    EmptyStateView(
                        icon: "bolt.badge.clock",
                        title: "No Workers Found",
                        message: "You haven't deployed any Cloudflare Workers scripts to this account yet.",
                        actionTitle: "Create Worker",
                        action: { showingCreateWorkerSheet = true }
                    )
                } else if viewModel.filteredWorkers.isEmpty {
                    EmptyStateView.search(query: viewModel.searchText) {
                        viewModel.searchText = ""
                    }
                } else {
                    List {
                        ForEach(viewModel.filteredWorkers) { worker in
                            NavigationLink {
                                WorkerDetailView(accountId: accountId, worker: worker)
                            } label: {
                                WorkerRowView(worker: worker)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    workerToDelete = worker
                                    showingDeleteWorkerAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            } else {
                if viewModel.pages.isEmpty {
                    EmptyStateView(
                        icon: "doc.text.image",
                        title: "No Pages Projects",
                        message: "You haven't created any Cloudflare Pages projects in this account yet.",
                        actionTitle: "Create Project",
                        action: { showingCreatePagesSheet = true }
                    )
                } else if viewModel.filteredPages.isEmpty {
                    EmptyStateView.search(query: viewModel.searchText) {
                        viewModel.searchText = ""
                    }
                } else {
                    List {
                        ForEach(viewModel.filteredPages) { page in
                            NavigationLink {
                                PagesProjectDetailView(accountId: accountId, project: page)
                            } label: {
                                HStack(alignment: .center, spacing: 14) {
                                    Image(systemName: "doc.richtext.fill")
                                        .font(.body)
                                        .foregroundStyle(.blue)
                                        .frame(width: 32, height: 32)
                                        .background(Color.blue.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
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
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.triangle.branch")
                                                .font(.caption2)
                                            Text(branch)
                                                .font(.caption2)
                                        }
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                                        .cornerRadius(6)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    projectToDelete = page
                                    showingDeletePagesAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
    }
}

struct WorkerRowView: View {
    let worker: WorkerScript
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "bolt.fill")
                .font(.body)
                .foregroundStyle(.orange)
                .frame(width: 32, height: 32)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(worker.id)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                if let mod = worker.modifiedOn {
                    Text("Modified: \(String(mod.prefix(10)))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let routes = worker.routes, !routes.isEmpty {
                Text("\(routes.count) Route(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct WorkerCreateSheetView: View {
    @ObservedObject var viewModel: WorkersViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var workerName = ""
    @State private var selectedTemplateIndex = 0
    @State private var scriptCode = """
    export default {
      async fetch(request, env, ctx) {
        return new Response("Hello from Cloudflare Workers!");
      }
    };
    """
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    let templates: [(String, String)] = [
        ("Hello World", """
        export default {
          async fetch(request, env, ctx) {
            return new Response("Hello from Cloudflare Workers!");
          }
        };
        """),
        ("JSON REST API", """
        export default {
          async fetch(request, env, ctx) {
            const data = {
              status: "ok",
              timestamp: new Date().toISOString(),
              ip: request.headers.get("cf-connecting-ip") || "127.0.0.1"
            };
            return new Response(JSON.stringify(data, null, 2), {
              headers: { "content-type": "application/json" }
            });
          }
        };
        """),
        ("Reverse Proxy", """
        export default {
          async fetch(request, env, ctx) {
            const targetUrl = new URL(request.url);
            targetUrl.hostname = "example.com";
            
            const newRequest = new Request(targetUrl.toString(), request);
            return fetch(newRequest);
          }
        };
        """),
        ("URL Redirect", """
        export default {
          async fetch(request, env, ctx) {
            return Response.redirect("https://cloudflare.com", 301);
          }
        };
        """)
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Worker Name"), footer: Text("Name can contain lowercase letters, numbers, and dashes.")) {
                    TextField("my-worker", text: $workerName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Choose Template")) {
                    Picker("Template", selection: $selectedTemplateIndex) {
                        ForEach(0..<templates.count, id: \.self) { idx in
                            Text(templates[idx].0).tag(idx)
                        }
                    }
                    .onChange(of: selectedTemplateIndex) { newIdx in
                        scriptCode = templates[newIdx].1
                    }
                }
                
                Section(header: Text("Starter JavaScript Code")) {
                    TextEditor(text: $scriptCode)
                        .font(.body)
                        .frame(minHeight: 180)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Worker")
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
                                try await viewModel.createWorker(
                                    name: workerName.trimmingCharacters(in: .whitespaces),
                                    code: scriptCode
                                )
                                ToastManager.shared.showSuccess("Worker Deployed", message: workerName)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isCreating = false
                        }
                    }
                    .disabled(workerName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .toastContainer()
        }
    }
}

struct PagesCreateProjectSheetView: View {
    @ObservedObject var viewModel: WorkersViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectName = ""
    @State private var productionBranch = "main"
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Project Information"), footer: Text("Pages projects deploy Jamstack frontend websites on Cloudflare edge.")) {
                    TextField("Project Name", text: $projectName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Production Branch", text: $productionBranch)
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
            .navigationTitle("New Pages Project")
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
                                    name: projectName.trimmingCharacters(in: .whitespaces),
                                    branch: productionBranch.trimmingCharacters(in: .whitespaces)
                                )
                                ToastManager.shared.showSuccess("Pages Project", message: "Project created successfully")
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isCreating = false
                        }
                    }
                    .disabled(projectName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .toastContainer()
        }
    }
}
