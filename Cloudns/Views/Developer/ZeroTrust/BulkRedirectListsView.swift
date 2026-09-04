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
                Section("Redirect Lists (\(viewModel.lists.count))") {
                    ForEach(viewModel.filteredLists) { item in
                        NavigationLink(destination: RedirectListDetailView(accountId: accountId, list: item)) {
                            listRow(item)
                        }
                        .contextMenu {
                            Button {
                                copyToClipboard(item.name, toast: "List Name Copied")
                            } label: {
                                Label("Copy List Name", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                copyToClipboard(item.id, toast: "List ID Copied")
                            } label: {
                                Label("Copy List ID", systemImage: "link")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                listToDelete = item
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete List", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                listToDelete = item
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
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Redirect Lists…",
            isEmpty: viewModel.hasFetchedData && viewModel.lists.isEmpty && viewModel.errorMessage == nil,
            emptyTitle: "No Bulk Redirect Lists",
            emptyDescription: "Bulk Redirects allow you to define thousands of URL redirects at the account level.",
            emptyActionTitle: "Create List",
            emptyAction: { showingCreateSheet = true },
            isSearchEmpty: viewModel.hasFetchedData && !viewModel.lists.isEmpty && viewModel.filteredLists.isEmpty && !viewModel.searchText.isEmpty,
            searchQuery: viewModel.searchText,
            errorMessage: viewModel.errorMessage.map { LocalizedStringKey($0) },
            retryAction: { Task { await viewModel.fetchLists() } }
        )
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
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateBulkRedirectListSheetView(viewModel: viewModel)
        }
        .confirmationDialog("Delete List", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: listToDelete) { item in
            Button("Delete '\(item.name)'", role: .destructive) {
                Task {
                    await viewModel.deleteList(id: item.id)
                    ToastManager.shared.showSuccess("Redirect List Deleted", icon: "trash.fill")
                    HapticManager.notification(.success)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text("Are you sure you want to delete redirect list '\(item.name)'?")
        }
        .refreshable {
            await viewModel.fetchLists()
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchLists()
            }
        }
    }
    
    @ViewBuilder
    private func listRow(_ item: RedirectList) -> some View {
        HStack(spacing: 12) {
            ListRowIcon(icon: "list.bullet.rectangle.portrait.fill", color: .teal)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: item.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let desc = item.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if let count = item.count {
                Text("\(count) items")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
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
                Section("List Information") {
                    TextField("List Name (e.g. legacy_domains)", text: $name)
                        .font(.body)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    
                    TextField("Description (Optional)", text: $description)
                        .font(.body)
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
                                HapticManager.notification(.success)
                                ToastManager.shared.showSuccess("Redirect List Created", icon: "list.bullet.rectangle.portrait.fill")
                                dismiss()
                            } else {
                                HapticManager.notification(.error)
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
