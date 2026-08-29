import Foundation
import SwiftUI

// MARK: - BulkRedirectListsView

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
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(RedirectList.placeholders) { placeholder in
                        listRow(placeholder)
                    }
                }
                .redacted(reason: .placeholder)
            } else if !viewModel.filteredLists.isEmpty {
                Section(header: Text("Redirect Lists (\(viewModel.lists.count))")) {
                    ForEach(viewModel.filteredLists) { item in
                        NavigationLink(destination: RedirectListDetailView(accountId: accountId, list: item)) {
                            listRow(item)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                listToDelete = item
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
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
                Task { await viewModel.deleteList(id: item.id) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text("Are you sure you want to delete redirect list '\(item.name)'?")
        }
        .refreshable {
            await viewModel.fetchLists()
        }
        .overlay {
            if viewModel.hasFetchedData {
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
        HStack(spacing: 12) {
            Image(systemName: "list.bullet.rectangle.portrait.fill")
                .foregroundStyle(.blue)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
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
        .padding(.vertical, 3)
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
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    
                    TextField("Description (Optional)", text: $description)
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
                                HIGFeedback.success()
                                dismiss()
                            } else {
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
