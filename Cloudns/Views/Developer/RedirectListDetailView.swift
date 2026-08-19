import SwiftUI

// MARK: - RedirectListDetailView

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
                    ForEach(RedirectListItem.placeholders) { placeholder in
                        redirectItemRow(placeholder)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                } else if items.isEmpty {
                    Text("No redirect items in this list.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(items) { item in
                        redirectItemRow(item)
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
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await fetchItems()
        }
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
            AddRedirectItemSheetView(accountId: accountId, listId: list.id) {
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
            self.items = try await BulkRedirectService.shared.listRedirectListItems(accountId: accountId, listId: list.id)
        } catch {
            self.items = []
        }
        isLoading = false
    }
    
    private func deleteItem(id: String) async {
        do {
            _ = try await BulkRedirectService.shared.deleteRedirectListItems(accountId: accountId, listId: list.id, itemIds: [id])
            ToastManager.shared.showSuccess("Item Deleted", message: "")
            await fetchItems()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
    
    @ViewBuilder
    private func redirectItemRow(_ item: RedirectListItem) -> some View {
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
    }
}
