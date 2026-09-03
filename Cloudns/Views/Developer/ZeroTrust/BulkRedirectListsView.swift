import Foundation
import SwiftUI

// MARK: - BulkRedirectListsView
// Apple HIG Compliant Cloudflare Account-Level Bulk Redirect Lists

struct BulkRedirectListsView: View {
    let accountId: String
    @StateObject private var viewModel: BulkRedirectsViewModel
    @State private var showingCreateSheet = false
    @State private var listToDelete: RedirectList?
    @State private var showingDeleteAlert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: BulkRedirectsViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if !viewModel.filteredLists.isEmpty {
                Section(header: Text("Redirect Lists (\(viewModel.lists.count))")) {
                    ForEach(viewModel.filteredLists) { item in
                        NavigationLink(destination: RedirectListDetailView(accountId: accountId, list: item)) {
                            listRow(item)
                        }
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = item.name
                                ToastManager.shared.showCopied("List Name Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy List Name", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                UIPasteboard.general.string = item.id
                                ToastManager.shared.showCopied("List ID Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy List ID", systemImage: "link")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                listToDelete = item
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete List", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                listToDelete = item
                                showingDeleteAlert = true
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
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Lists"
        )
        .navigationTitle("Redirect Lists")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create List")
                .higTouchTarget(44)
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateBulkRedirectListSheetView(viewModel: viewModel)
                .higToast()
        }
        .confirmationDialog("Delete List", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: listToDelete) { item in
            Button("Delete '\(item.name)'", role: .destructive) {
                Task {
                    await viewModel.deleteList(id: item.id)
                    ToastManager.shared.showSuccess("Redirect List Deleted", icon: "trash.fill")
                    HIGFeedback.success()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text("Are you sure you want to delete redirect list '\(item.name)'?")
        }
        .refreshable {
            await viewModel.fetchLists()
        }
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Redirect Lists…"))
            } else if viewModel.hasFetchedData {
                if let err = viewModel.errorMessage, viewModel.lists.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(err),
                            retryAction: { Task { await viewModel.fetchLists() } }
                        )
                    )
                } else if viewModel.lists.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Bulk Redirect Lists",
                            systemImage: "arrow.triangle.swap",
                            description: "Bulk Redirects allow you to define thousands of URL redirects at the account level.",
                            actionTitle: "Create List",
                            action: { showingCreateSheet = true }
                        )
                    )
                } else if viewModel.filteredLists.isEmpty && !viewModel.searchText.isEmpty {
                    HIGContentState(.search(query: viewModel.searchText))
                }
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchLists()
            }
        }
    }
    
    @ViewBuilder
    private func listRow(_ item: RedirectList) -> some View {
        HStack(spacing: HIGTokens.Spacing.md) {
            ListRowIcon(icon: "list.bullet.rectangle.portrait.fill", color: .teal)
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text(verbatim: item.name)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let desc = item.description, !desc.isEmpty {
                    Text(desc)
                        .font(HIGTypography.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if let count = item.count {
                Text("\(count) items")
                    .font(HIGTypography.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
}

// MARK: - CreateBulkRedirectListSheetView (Inlined & Cohesive)

struct CreateBulkRedirectListSheetView: View {
    @ObservedObject var viewModel: BulkRedirectsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("List Information")) {
                    TextField("List Name (e.g. legacy_domains)", text: $name)
                        .font(HIGTypography.body)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    
                    TextField("Description (Optional)", text: $description)
                        .font(HIGTypography.body)
                        .submitLabel(.done)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Redirect List")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .higTouchTarget(44)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            let success = await viewModel.createList(
                                name: name.trimmingCharacters(in: .whitespaces),
                                description: description.isEmpty ? nil : description
                            )
                            if success {
                                HIGFeedback.success()
                                ToastManager.shared.showSuccess("Redirect List Created", icon: "list.bullet.rectangle.portrait.fill")
                                dismiss()
                            } else {
                                HIGFeedback.error()
                            }
                            isCreating = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                    .higTouchTarget(44)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}
