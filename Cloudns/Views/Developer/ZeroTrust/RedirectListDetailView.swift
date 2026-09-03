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
            Section(header: Text("List Metadata")) {
                LabeledContent("Name", value: list.name)
                    .font(HIGTypography.body)
                
                LabeledContent("List ID") {
                    Text(list.id)
                        .font(HIGTypography.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            
            if !filteredItems.isEmpty {
                Section(header: Text("Redirect Items (\(filteredItems.count))")) {
                    ForEach(filteredItems) { item in
                        redirectItemRow(item)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = item.redirect.sourceUrl
                                    ToastManager.shared.showCopied("Source URL Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Source URL", systemImage: "doc.on.doc")
                                }
                                
                                Button {
                                    UIPasteboard.general.string = item.redirect.targetUrl
                                    ToastManager.shared.showCopied("Target URL Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Target URL", systemImage: "link")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    HIGFeedback.impact(.medium)
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
                                    HIGFeedback.impact(.medium)
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
            if isLoading && items.isEmpty {
                HIGContentState(.loading(message: "Loading Redirect Items…"))
            } else if !isLoading {
                if items.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Redirect Items",
                            systemImage: "arrow.triangle.swap",
                            description: "Add URL redirect rules to this list.",
                            actionTitle: "Add Redirect Item",
                            action: { showingAddSheet = true }
                        )
                    )
                } else if filteredItems.isEmpty && !searchText.isEmpty {
                    HIGContentState(.search(query: searchText))
                }
            }
        }
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
                .higTouchTarget(44)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddRedirectItemSheetView(accountId: accountId, listId: list.id) {
                Task { await fetchItems() }
            }
            .higToast()
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
            HIGFeedback.success()
            await fetchItems()
        } catch {
            HIGFeedback.error()
        }
    }
    
    @ViewBuilder
    private func redirectItemRow(_ item: RedirectListItem) -> some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
            HStack {
                Text(verbatim: item.redirect.sourceUrl)
                    .font(HIGTypography.caption.monospaced())
                Spacer()
                Text("\(item.redirect.statusCode ?? 301)")
                    .font(HIGTypography.caption2.weight(.bold))
                    .foregroundStyle(.indigo)
            }
            
            HStack(spacing: HIGTokens.Spacing.xs) {
                Image(systemName: "arrow.turn.down.right")
                    .font(HIGTypography.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(verbatim: item.redirect.targetUrl)
                    .font(HIGTypography.caption.monospaced())
                    .foregroundStyle(Color.higAccent)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
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
                Section(header: Text("URL Mapping")) {
                    TextField("Source URL (e.g. example.com/old)", text: $sourceUrl)
                        .font(HIGTypography.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    
                    TextField("Target URL (e.g. https://example.com/new)", text: $targetUrl)
                        .font(HIGTypography.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                
                Section(header: Text("Redirect Behavior")) {
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
                            .font(HIGTypography.caption)
                            .foregroundStyle(HIGColors.error)
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
                        .higTouchTarget(44)
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
                                HIGFeedback.success()
                                ToastManager.shared.showSuccess("Redirect Item Added", icon: "arrow.triangle.swap")
                                onSaved()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(sourceUrl.trimmingCharacters(in: .whitespaces).isEmpty || targetUrl.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                    .higTouchTarget(44)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
