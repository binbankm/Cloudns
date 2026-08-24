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
            CloudnsSearchBar(
                text: $viewModel.searchText,
                prompt: viewModel.selectedSegment == 0 ? "Search Workers" : "Search Pages"
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(Color(.systemGroupedBackground))
            
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
                    await viewModel.deleteWorker(name: worker.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { worker in
            Text("Are you sure you want to permanently delete Worker '\(worker.id)'? Associated routes and scripts will be removed.")
        }
        .confirmationDialog("Delete Pages Project", isPresented: $showingDeletePagesAlert, titleVisibility: .visible, presenting: pagesProjectToDelete) { proj in
            Button("Delete '\(proj.name)'", role: .destructive) {
                Task {
                    await viewModel.deletePagesProject(name: proj.name)
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
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    if viewModel.selectedSegment == 0 {
                        ForEach(WorkerScript.placeholders) { script in
                            WorkerRowView(worker: script)
                        }
                    } else {
                        ForEach(PagesProject.placeholders) { proj in
                            pagesRow(proj)
                        }
                    }
                }
                .skeletonLoading(true)
            } else if viewModel.selectedSegment == 0 {
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
            if viewModel.hasFetchedData {
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
                                icon: "macwindow",
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
            Image(systemName: "macwindow")
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
