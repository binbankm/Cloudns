import Foundation
import SwiftUI

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
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
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
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("Bulk Redirects")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Lists")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create List")
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateBulkRedirectListSheet(viewModel: viewModel)
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
            if !viewModel.hasFetchedData && viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.hasFetchedData {
                if let err = viewModel.errorMessage, viewModel.lists.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(err),
                            retryAction: { Task { await viewModel.fetchLists() } }
                        )
                    )
                } else if viewModel.lists.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "arrow.triangle.swap",
                            title: "No Bulk Redirect Lists",
                            message: "Bulk Redirects allow you to define thousands of URL redirects at the account level.",
                            actionTitle: "Create List",
                            action: { showingCreateSheet = true }
                        )
                    )
                } else if viewModel.filteredLists.isEmpty && !viewModel.searchText.isEmpty {
                    StateOverlayView(
                        state: .search(
                            query: viewModel.searchText,
                            clearAction: { viewModel.searchText = "" }
                        )
                    )
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
            Image(systemName: "arrow.triangle.swap")
                .foregroundStyle(.indigo)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(Color.indigo.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let desc = item.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let count = item.count {
                Text("\(count) items")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct RedirectListDetailView: View {
    let accountId: String
    let list: RedirectList
    @State private var items: [RedirectListItem] = []
    @State private var isLoading = false
    @State private var showingAddSheet = false
    
    var body: some View {
        List {
            Section(header: Text("List Metadata")) {
                HStack {
                    Text("Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(list.name)
                        .font(.body.weight(.medium))
                }
                
                HStack {
                    Text("List ID")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(list.id)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            
            Section(header: Text("Redirect Items (\(items.count))")) {
                if isLoading && items.isEmpty {
                    ProgressView()
                } else if items.isEmpty {
                    Text("No redirect items in this list.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.redirect.sourceUrl)
                                    .font(.caption.monospaced())
                                Spacer()
                                Text("\(item.redirect.statusCode ?? 301)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.indigo)
                            }
                            
                            HStack {
                                Image(systemName: "arrow.turn.down.right")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .accessibilityHidden(true)
                                Text(item.redirect.targetUrl)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.vertical, 2)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                Task { await deleteItem(id: item.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Redirect Item")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddRedirectItemSheet(accountId: accountId, listId: list.id) {
                Task { await fetchItems() }
            }
        }
        .task {
            await fetchItems()
        }
    }
    
    private func fetchItems() async {
        isLoading = true
        do {
            self.items = try await CloudflareAPIClient.shared.listRedirectListItems(accountId: accountId, listId: list.id)
        } catch {
            print("Failed to load items: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    private func deleteItem(id: String) async {
        do {
            _ = try await CloudflareAPIClient.shared.deleteRedirectListItems(accountId: accountId, listId: list.id, itemIds: [id])
            ToastManager.shared.showSuccess("Item Deleted", message: "")
            await fetchItems()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}

struct AddRedirectItemSheet: View {
    let accountId: String
    let listId: String
    let onAdded: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var sourceUrl = ""
    @State private var targetUrl = ""
    @State private var statusCode = 301
    @State private var preserveQueryString = true
    @State private var subpathMatching = false
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Source URL")) {
                    TextField("https://old.example.com/page", text: $sourceUrl)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Target URL")) {
                    TextField("https://new.example.com/target", text: $targetUrl)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Settings")) {
                    Picker("Status Code", selection: $statusCode) {
                        Text("301 Permanent Redirect").tag(301)
                        Text("302 Temporary Redirect").tag(302)
                        Text("307 Temporary Redirect").tag(307)
                        Text("308 Permanent Redirect").tag(308)
                    }
                    
                    Toggle("Preserve Query String", isOn: $preserveQueryString)
                    Toggle("Subpath Matching", isOn: $subpathMatching)
                }
            }
            .navigationTitle("New Redirect Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        Task {
                            isSubmitting = true
                            let item = RedirectItemDetail(
                                sourceUrl: sourceUrl.trimmingCharacters(in: .whitespacesAndNewlines),
                                targetUrl: targetUrl.trimmingCharacters(in: .whitespacesAndNewlines),
                                statusCode: statusCode,
                                preserveQueryString: preserveQueryString,
                                includeSubdomains: false,
                                subpathMatching: subpathMatching,
                                preservePathSuffix: false
                            )
                            do {
                                _ = try await CloudflareAPIClient.shared.createRedirectListItems(accountId: accountId, listId: listId, items: [item])
                                ToastManager.shared.showSuccess("Item Added", message: "")
                                onAdded()
                                dismiss()
                            } catch {
                                ToastManager.shared.showError("Add Failed", message: error.localizedDescription)
                            }
                            isSubmitting = false
                        }
                    }
                    .disabled(sourceUrl.isEmpty || targetUrl.isEmpty || isSubmitting)
                }
            }
        }
    }
}

struct CreateBulkRedirectListSheet: View {
    @ObservedObject var viewModel: BulkRedirectsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("List Name")) {
                    TextField("marketing-redirects", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Description (Optional)")) {
                    TextField("Redirects for domain migration", text: $description)
                }
            }
            .navigationTitle("New Redirect List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            isSubmitting = true
                            let clean = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                            let success = await viewModel.createList(name: clean, description: description.isEmpty ? nil : description)
                            if success { dismiss() }
                            isSubmitting = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
        }
    }
}
