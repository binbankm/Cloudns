import Foundation
import SwiftUI

// MARK: - DurableObjectsView
// Apple HIG Compliant Cloudflare Durable Objects Namespace Browser

struct DurableObjectsView: View {
    let accountId: String
    @StateObject private var viewModel: DurableObjectsViewModel
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: DurableObjectsViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if !viewModel.filteredNamespaces.isEmpty {
                Section(header: Text("Namespaces (\(viewModel.namespaces.count))")) {
                    ForEach(viewModel.filteredNamespaces) { ns in
                        NavigationLink(destination: DurableObjectNamespaceDetailView(accountId: accountId, namespace: ns)) {
                            nsRow(ns)
                        }
                        .contextMenu {
                            Button {
                                copyToClipboard(ns.id, toast: "Namespace ID Copied")
                            } label: {
                                Label("Copy Namespace ID", systemImage: "doc.on.doc")
                            }
                            
                            if let s = ns.script {
                                Button {
                                    copyToClipboard(s, toast: "Script Name Copied")
                                } label: {
                                    Label("Copy Script Name", systemImage: "curlybraces")
                                }
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
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Namespaces"
        )
        .navigationTitle("Durable Objects")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchNamespaces()
        }
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Durable Objects…",
            isEmpty: viewModel.hasFetchedData && viewModel.namespaces.isEmpty,
            emptyTitle: "No Durable Objects",
            emptySystemImage: "cube.fill",
            emptyDescription: "Durable Objects namespaces are created via Wrangler migrations inside your Worker code.",
            emptyActionTitle: "Refresh",
            emptyAction: { Task { await viewModel.fetchNamespaces() } },
            isSearchEmpty: viewModel.hasFetchedData && viewModel.filteredNamespaces.isEmpty && !viewModel.searchText.isEmpty,
            searchQuery: viewModel.searchText,
            errorMessage: (viewModel.hasFetchedData && viewModel.namespaces.isEmpty) ? viewModel.errorMessage.map { LocalizedStringKey($0) } : nil,
            retryAction: { Task { await viewModel.fetchNamespaces() } }
        )
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchNamespaces()
            }
        }
    }
    
    @ViewBuilder
    private func nsRow(_ ns: DurableObjectNamespace) -> some View {
        HStack(spacing: 12) {
            ListRowIcon(icon: "cube.fill", color: .cyan)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(ns.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let s = ns.script {
                    Text("Script: \(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let cls = ns.class {
                Text(cls)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.cyan.opacity(0.12)))
            }
        }
        .padding(.vertical, 2)
    }
}
