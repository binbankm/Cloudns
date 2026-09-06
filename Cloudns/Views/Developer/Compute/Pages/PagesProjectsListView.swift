import SwiftUI

// MARK: - PagesProjectsListView (Pure List - No Tags)
// Apple HIG Compliant Cloudflare Pages Overview

struct PagesProjectsListView: View {
    let accountId: String
    @StateObject private var viewModel: WorkersViewModel
    @State private var showingCreatePagesSheet = false
    @State private var pagesProjectToDelete: PagesProject?
    @State private var showingDeletePagesAlert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: WorkersViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if !viewModel.filteredPages.isEmpty {
                Section(header: Text("Pages Projects (\(viewModel.filteredPages.count))")) {
                    ForEach(viewModel.filteredPages) { page in
                        NavigationLink {
                            PagesProjectDetailView(accountId: accountId, project: page)
                        } label: {
                            pagesRow(page)
                        }
                        .contextMenu {
                            if let sub = page.subdomain {
                                Button {
                                    copyToClipboard(sub, toast: "Subdomain Copied")
                                } label: {
                                    Label("Copy Subdomain", systemImage: "link")
                                }
                            }
                            
                            Button {
                                copyToClipboard(page.name, toast: "Project Name Copied")
                            } label: {
                                Label("Copy Project Name", systemImage: "doc.on.doc")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                pagesProjectToDelete = page
                                showingDeletePagesAlert = true
                            } label: {
                                Label("Delete Project", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                pagesProjectToDelete = page
                                showingDeletePagesAlert = true
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
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Pages Projects…",
            isEmpty: viewModel.hasFetchedData && viewModel.pages.isEmpty,
            emptyTitle: "No Pages Projects Found",
            emptySystemImage: "macwindow",
            emptyDescription: "You haven't connected or deployed any Cloudflare Pages projects yet.",
            emptyActionTitle: "Create Pages Project",
            emptyAction: { showingCreatePagesSheet = true },
            isSearchEmpty: viewModel.hasFetchedData && viewModel.filteredPages.isEmpty && !viewModel.searchText.isEmpty,
            searchQuery: viewModel.searchText,
            errorMessage: (viewModel.hasFetchedData && viewModel.pages.isEmpty) ? viewModel.errorMessage.map { LocalizedStringKey($0) } : nil,
            retryAction: { Task { await viewModel.fetchData() } }
        )
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Pages Projects"
        )
        .navigationTitle("Pages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreatePagesSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create Pages Project")
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingCreatePagesSheet) {
            PagesCreateProjectSheetView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Delete Pages Project", isPresented: $showingDeletePagesAlert, titleVisibility: .visible, presenting: pagesProjectToDelete) { proj in
            Button("Delete '\(proj.name)'", role: .destructive) {
                Task {
                    await viewModel.deletePagesProject(name: proj.name)
                    ToastManager.shared.showSuccess("Pages Project Deleted", icon: "trash.fill")
                    HapticManager.notification(.success)
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
    private func pagesRow(_ page: PagesProject) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ListRowIcon(icon: "macwindow", color: .purple)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(page.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let sub = page.subdomain {
                    Text(sub)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let branch = page.productionBranch {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.caption2)
                    Text(branch)
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.blue.opacity(0.12)))
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - PagesCreateProjectSheetView (Inlined & Cohesive)

struct PagesCreateProjectSheetView: View {
    @ObservedObject var viewModel: WorkersViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var branch = "main"
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Project Name"), footer: Text("Unique project name across your account.")) {
                    TextField("my-pages-site", text: $name)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Production Branch")) {
                    TextField("main", text: $branch)
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
            .navigationTitle("New Pages Project")
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
                                try await viewModel.createPagesProject(
                                    name: name.trimmingCharacters(in: .whitespaces),
                                    branch: branch.trimmingCharacters(in: .whitespaces)
                                )
                                ToastManager.shared.showSuccess("Pages Project Created", icon: "macwindow")
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
