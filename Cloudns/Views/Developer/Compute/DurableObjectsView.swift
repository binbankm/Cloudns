import Foundation
import SwiftUI

struct DurableObjectsView: View {
    let accountId: String
    @StateObject private var viewModel: DurableObjectsViewModel
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: DurableObjectsViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(DurableObjectNamespace.placeholders) { placeholder in
                        nsRow(placeholder)
                    }
                }
                .redacted(reason: .placeholder)
            } else if !viewModel.filteredNamespaces.isEmpty {
                Section(header: Text("Namespaces (\(viewModel.namespaces.count))")) {
                    ForEach(viewModel.filteredNamespaces) { ns in
                        NavigationLink(destination: DurableObjectNamespaceDetailView(accountId: accountId, namespace: ns)) {
                            nsRow(ns)
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
            prompt: "Search Namespaces"
        )
        .navigationTitle("Durable Objects")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchNamespaces()
        }
        .overlay {
            if viewModel.hasFetchedData {
                if let err = viewModel.errorMessage, viewModel.namespaces.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(err),
                            retryAction: { Task { await viewModel.fetchNamespaces() } }
                        )
                    )
                } else if viewModel.namespaces.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Durable Objects",
                            systemImage: "cube.fill",
                            description: "Durable Objects namespaces are created via Wrangler migrations inside your Worker code.",
                            actionTitle: "Refresh",
                            action: { Task { await viewModel.fetchNamespaces() } }
                        )
                    )
                } else if viewModel.filteredNamespaces.isEmpty && !viewModel.searchText.isEmpty {
                    HIGContentState(.search(query: viewModel.searchText))
                }
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchNamespaces()
            }
        }
    }
    
    @ViewBuilder
    private func nsRow(_ ns: DurableObjectNamespace) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "cube.fill")
                .foregroundStyle(.cyan)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(Color.cyan.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
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
                HIGBadge(.custom(color: .cyan, text: cls), isCompact: true)
            }
        }
        .padding(.vertical, 2)
    }
}
