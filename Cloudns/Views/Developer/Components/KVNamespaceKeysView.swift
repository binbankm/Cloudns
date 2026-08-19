import SwiftUI

// MARK: - KVNamespaceKeysView

struct KVNamespaceKeysView: View {
    let accountId: String
    let namespace: KVNamespace
    @StateObject private var viewModel: KVNamespaceDetailViewModel
    @State private var searchKey: String = ""
    @State private var showingAddSheet = false
    @State private var showingValueSheet = false
    
    init(accountId: String, namespace: KVNamespace) {
        self.accountId = accountId
        self.namespace = namespace
        _viewModel = StateObject(wrappedValue: KVNamespaceDetailViewModel(accountId: accountId, namespace: namespace))
    }
    
    var filteredKeys: [KVKey] {
        if searchKey.isEmpty { return viewModel.keys }
        return viewModel.keys.filter { $0.name.localizedCaseInsensitiveContains(searchKey) }
    }
    
    var body: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(KVKey.placeholders) { key in
                        keyRow(key)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
            } else if !filteredKeys.isEmpty {
                Section(header: Text("Keys (\(filteredKeys.count))")) {
                    ForEach(filteredKeys) { key in
                        Button {
                            Task {
                                await viewModel.fetchValue(key: key.name)
                                showingValueSheet = true
                            }
                        } label: {
                            keyRow(key)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                Task {
                                    do {
                                        try await viewModel.deleteKey(key: key.name)
                                        ToastManager.shared.showSuccess("Key Deleted", message: key.name)
                                    } catch {
                                        ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                                    }
                                }
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
        .navigationTitle(namespace.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchKey, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Keys")
        .refreshable {
            await viewModel.fetchKeys()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Key")
            }
        }
        .sheet(isPresented: $showingValueSheet) {
            KVValueSheetView(
                keyName: viewModel.selectedKey ?? "",
                valueText: viewModel.selectedKeyValue ?? "No value",
                isLoading: viewModel.isValueLoading
            )
        }
        .sheet(isPresented: $showingAddSheet) {
            KVAddKeySheetView(viewModel: viewModel)
        }
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.keys.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchKeys() } }
                        )
                    )
                } else if viewModel.keys.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "tray",
                            title: "Empty Namespace",
                            message: "This KV namespace currently contains no keys.",
                            actionTitle: "Add Key",
                            action: { showingAddSheet = true }
                        )
                    )
                } else if filteredKeys.isEmpty && !searchKey.isEmpty {
                    StateOverlayView(
                        state: .search(
                            query: searchKey,
                            clearAction: { searchKey = "" }
                        )
                    )
                }
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchKeys()
            }
        }
    }
    
    @ViewBuilder
    private func keyRow(_ key: KVKey) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(key.name)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.primary)
                
                if let exp = key.expiration {
                    Text("Expires: \(exp)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color(.tertiaryLabel))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 3)
    }
}
