import SwiftUI

// MARK: - RedirectListDetailView
// Apple HIG Compliant Cloudflare Bulk Redirect List Inspector & URL Item Mapper

struct RedirectListDetailView: View {
    let accountId: String
    let list: RedirectList
    @State private var items: [RedirectListItem] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var showingAddSheet = false
    @State private var itemToDelete: RedirectListItem?
    @State private var showingDeleteConfirm = false
    
    private var filteredItems: [RedirectListItem] {
        if searchText.isEmpty { return items }
        let query = searchText.lowercased()
        return items.filter { item in
            item.redirect.sourceUrl.lowercased().contains(query) ||
            item.redirect.targetUrl.lowercased().contains(query)
        }
    }
    
    var body: some View {
        List {
            Section("List Metadata") {
                LabeledContent("Name", value: list.name)
                    .font(.body)
                
                LabeledContent("List ID") {
                    Text(list.id)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            
            if !filteredItems.isEmpty {
                Section("Redirect Items (\(filteredItems.count))") {
                    ForEach(filteredItems) { item in
                        redirectItemRow(item)
                            .contextMenu {
                                Button {
                                    copyToClipboard(item.redirect.sourceUrl, toast: "Source URL Copied")
                                } label: {
                                    Label("Copy Source URL", systemImage: "doc.on.doc")
                                }
                                
                                Button {
                                    copyToClipboard(item.redirect.targetUrl, toast: "Target URL Copied")
                                } label: {
                                    Label("Copy Target URL", systemImage: "link")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    itemToDelete = item
                                    showingDeleteConfirm = true
                                } label: {
                                    Label("Delete Redirect Item", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    itemToDelete = item
                                    showingDeleteConfirm = true
                                    HapticManager.impact(.medium)
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
            isLoading: isLoading && items.isEmpty,
            loadingMessage: "Loading Redirect Items…",
            isEmpty: !isLoading && items.isEmpty,
            emptyTitle: "No Redirect Items",
            emptyDescription: "Add URL redirect rules to this list.",
            emptyActionTitle: "Add Redirect Item",
            emptyAction: { showingAddSheet = true },
            isSearchEmpty: !isLoading && !items.isEmpty && filteredItems.isEmpty && !searchText.isEmpty,
            searchQuery: searchText
        )
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Redirect Items"
        )
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await fetchItems()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Redirect Item")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddRedirectItemSheetView(accountId: accountId, listId: list.id) {
                Task { await fetchItems() }
            }
        }
        .confirmationDialog("Delete Redirect Item", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            if let item = itemToDelete {
                Button("Delete '\(item.redirect.sourceUrl)'", role: .destructive) {
                    Task {
                        await deleteItem(id: item.id)
                        ToastManager.shared.showSuccess("Redirect Item Deleted", icon: "trash.fill")
                        itemToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                itemToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this redirect rule?")
        }
        .task {
            await fetchItems()
        }
    }
    
    private func fetchItems() async {
        isLoading = true
        do {
            self.items = try await BulkRedirectService.shared.listRedirectListItems(accountId: accountId, listId: list.id)
        } catch {
            self.items = []
        }
        isLoading = false
    }
    
    private func deleteItem(id: String) async {
        do {
            _ = try await BulkRedirectService.shared.deleteRedirectListItems(accountId: accountId, listId: list.id, itemIds: [id])
            HapticManager.notification(.success)
            await fetchItems()
        } catch {
            HapticManager.notification(.error)
        }
    }
    
    @ViewBuilder
    private func redirectItemRow(_ item: RedirectListItem) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(verbatim: item.redirect.sourceUrl)
                    .font(.caption.monospaced())
                Spacer()
                Text("\(item.redirect.statusCode ?? 301)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.indigo)
            }
            
            HStack(spacing: 6) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(verbatim: item.redirect.targetUrl)
                    .font(.caption.monospaced())
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - AddRedirectItemSheetView (Inlined & Cohesive)

struct AddRedirectItemSheetView: View {
    let accountId: String
    let listId: String
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var sourceUrl = ""
    @State private var targetUrl = ""
    @State private var statusCode = 301
    @State private var preserveQueryString = false
    @State private var subpathMatching = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("URL Mapping") {
                    TextField("Source URL (e.g. example.com/old)", text: $sourceUrl)
                        .font(.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    
                    TextField("Target URL (e.g. https://example.com/new)", text: $targetUrl)
                        .font(.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                
                Section("Redirect Behavior") {
                    Picker("Status Code", selection: $statusCode) {
                        Text("301 (Permanent)").tag(301)
                        Text("302 (Temporary)").tag(302)
                        Text("307 (Temporary Redirect)").tag(307)
                        Text("308 (Permanent Redirect)").tag(308)
                    }
                    
                    Toggle("Preserve Query String", isOn: $preserveQueryString)
                    Toggle("Subpath Matching", isOn: $subpathMatching)
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
            .navigationTitle("Add Redirect Item")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            let item = RedirectItemDetail(
                                sourceUrl: sourceUrl.trimmingCharacters(in: .whitespaces),
                                targetUrl: targetUrl.trimmingCharacters(in: .whitespaces),
                                statusCode: statusCode,
                                preserveQueryString: preserveQueryString,
                                subpathMatching: subpathMatching
                            )
                            do {
                                _ = try await BulkRedirectService.shared.createRedirectListItems(
                                    accountId: accountId,
                                    listId: listId,
                                    items: [item]
                                )
                                HapticManager.notification(.success)
                                ToastManager.shared.showSuccess("Redirect Item Added", icon: "arrow.triangle.swap")
                                onSaved()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.notification(.error)
                            }
                            isSaving = false
                        }
                    }
                    .disabled(sourceUrl.trimmingCharacters(in: .whitespaces).isEmpty || targetUrl.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
