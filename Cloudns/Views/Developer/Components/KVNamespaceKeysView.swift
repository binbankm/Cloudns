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
        return viewModel.keys.filter { $0.name.localizedStandardContains(searchKey) }
    }
    
    var body: some View {
        List {
            // MARK: - Namespace Metadata (Hidden during search)
            if searchKey.isEmpty {
                Section(header: Text("Namespace Information")) {
                    HStack {
                        Text("Namespace Name")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(namespace.title)
                            .font(.body.weight(.medium))
                    }
                    
                    HStack {
                        Text("Namespace ID")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(namespace.id)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        
                        Button {
                            UIPasteboard.general.string = namespace.id
                            HapticManager.impact(.light)
                            ToastManager.shared.showCopied("Namespace ID copied")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption2)
                                .foregroundStyle(.purple)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Copy Namespace ID")
                    }
                }
            }
            
            // MARK: - Keys List
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section(header: Text("Keys")) {
                    ForEach(KVKey.placeholders) { key in
                        keyRow(key)
                    }
                }
                .redacted(reason: .placeholder)
            } else if !filteredKeys.isEmpty {
                Section(header: Text("Keys (\(filteredKeys.count))")) {
                    ForEach(filteredKeys) { key in
                        Button {
                            HapticManager.impact(.light)
                            viewModel.selectedKey = key.name
                            viewModel.selectedKeyValue = nil
                            viewModel.isValueLoading = true
                            showingValueSheet = true
                            Task {
                                await viewModel.fetchValue(key: key.name)
                            }
                        } label: {
                            keyRow(key)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = key.name
                                HapticManager.notification(.success)
                                ToastManager.shared.showCopied("Key name copied")
                            } label: {
                                Label("Copy Key Name", systemImage: "doc.on.doc")
                            }
                            
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
                                Label("Delete Key", systemImage: "trash")
                            }
                        }
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
        .searchable(
            text: $searchKey,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search Keys"
        )
        .navigationTitle(namespace.title)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchKeys()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
                            icon: "key.horizontal.fill",
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
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "key.horizontal.fill")
                .font(.subheadline)
                .foregroundStyle(.purple)
                .frame(width: 32, height: 32)
                .background(Color.purple.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(key.name)
                    .font(.body.monospacedDigit().weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                
                if let exp = key.expiration {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("Expires: \(formatExpiration(exp))")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "infinity")
                            .font(.caption2)
                        Text("Never expires")
                            .font(.caption)
                    }
                    .foregroundStyle(Color(.tertiaryLabel))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color(.tertiaryLabel))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }
    
    private func formatExpiration(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return DateFormatters.mediumDateTime.string(from: date)
    }
}
