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
                                UIPasteboard.general.string = ns.id
                                ToastManager.shared.showCopied("Namespace ID Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy Namespace ID", systemImage: "doc.on.doc")
                            }
                            
                            if let s = ns.script {
                                Button {
                                    UIPasteboard.general.string = s
                                    ToastManager.shared.showCopied("Script Name Copied")
                                    HIGFeedback.copied()
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
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Durable Objects…"))
            } else if viewModel.hasFetchedData {
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
        HStack(spacing: HIGTokens.Spacing.md) {
            ListRowIcon(icon: "cube.fill", color: .cyan)
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text(ns.displayName)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let s = ns.script {
                    Text("Script: \(s)")
                        .font(HIGTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let cls = ns.class {
                HIGBadge(.custom(color: .cyan, text: cls), isCompact: true)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
}
