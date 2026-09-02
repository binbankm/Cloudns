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
                                    UIPasteboard.general.string = sub
                                    ToastManager.shared.showCopied("Subdomain Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Subdomain", systemImage: "link")
                                }
                            }
                            
                            Button {
                                UIPasteboard.general.string = page.name
                                ToastManager.shared.showCopied("Project Name Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy Project Name", systemImage: "doc.on.doc")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                pagesProjectToDelete = page
                                showingDeletePagesAlert = true
                            } label: {
                                Label("Delete Project", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                pagesProjectToDelete = page
                                showingDeletePagesAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(HIGColors.error)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Pages Projects…"))
            } else if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.pages.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchData() } }
                        )
                    )
                } else if viewModel.pages.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Pages Projects Found",
                            systemImage: "macwindow",
                            description: "You haven't connected or deployed any Cloudflare Pages projects yet.",
                            actionTitle: "Create Pages Project",
                            action: { showingCreatePagesSheet = true }
                        )
                    )
                } else if viewModel.filteredPages.isEmpty && !viewModel.searchText.isEmpty {
                    HIGContentState(.search(query: viewModel.searchText))
                }
            }
        }
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
                .higTouchTarget()
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingCreatePagesSheet) {
            PagesCreateProjectSheetView(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .higToast()
        }
        .confirmationDialog("Delete Pages Project", isPresented: $showingDeletePagesAlert, titleVisibility: .visible, presenting: pagesProjectToDelete) { proj in
            Button("Delete '\(proj.name)'", role: .destructive) {
                Task {
                    await viewModel.deletePagesProject(name: proj.name)
                    ToastManager.shared.showSuccess("Pages Project Deleted", icon: "trash.fill")
                    HIGFeedback.success()
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
        HStack(alignment: .center, spacing: HIGTokens.Spacing.md) {
            ListRowIcon(icon: "macwindow", color: .purple)
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text(page.name)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let sub = page.subdomain {
                    Text(sub)
                        .font(HIGTypography.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let branch = page.productionBranch {
                HIGBadge(.custom(color: .blue, text: branch, icon: "arrow.triangle.branch"), isCompact: true)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
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
                            .font(HIGTypography.caption)
                            .foregroundStyle(HIGColors.error)
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
                                HIGFeedback.success()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
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
