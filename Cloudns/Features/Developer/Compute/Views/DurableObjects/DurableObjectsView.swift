import Foundation
import SwiftUI

struct DurableObjectsView: View {
    // MARK: - Properties
    let accountId: String
    @StateObject private var viewModel: DurableObjectsViewModel
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: DurableObjectsViewModel(accountId: accountId))
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $viewModel.searchText,
                prompt: "Search Namespaces"
            )
            .padding(.horizontal, CloudnsSpacing.md)
            .padding(.top, CloudnsSpacing.sm)
            .padding(.bottom, CloudnsSpacing.xs)
            .background(CloudnsColor.groupedBackground)
            
            List {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section {
                        ForEach(DurableObjectNamespace.placeholders) { placeholder in
                            nsRow(placeholder)
                        }
                    }
                    .skeletonLoading(true)
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
            .centerConstrainedWidth(maxWidth: 840)
        }
        .background(CloudnsColor.groupedBackground)
        .navigationTitle("Durable Objects")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchNamespaces()
        }
        .overlay {
            if viewModel.hasFetchedData {
                if let err = viewModel.errorMessage, viewModel.namespaces.isEmpty {
                    CloudnsStateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(err),
                            retryAction: { Task { await viewModel.fetchNamespaces() } }
                        )
                    )
                } else if viewModel.namespaces.isEmpty {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "cube.fill",
                            title: "No Durable Objects",
                            message: "Durable Objects namespaces are created via Wrangler migrations inside your Worker code.",
                            actionTitle: "Refresh",
                            action: { Task { await viewModel.fetchNamespaces() } }
                        )
                    )
                } else if viewModel.filteredNamespaces.isEmpty && !viewModel.searchText.isEmpty {
                    CloudnsStateOverlayView(
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
                await viewModel.fetchNamespaces()
            }
        }
    }
    
    @ViewBuilder
    // MARK: - Private Views
    private func nsRow(_ ns: DurableObjectNamespace) -> some View {
        HStack(spacing: CloudnsSpacing.mdSmall) {
            Image(systemName: "cube.fill")
                .foregroundStyle(.cyan)
                .font(.title3)
                .frame(width: CloudnsSize.controlHeightSmall, height: CloudnsSize.controlHeightSmall)
                .background(CloudnsColor.databaseMuted)
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
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
                CloudnsBadge(.custom(color: .cyan, text: cls), isCompact: true)
            }
        }
        .padding(.vertical, CloudnsSpacing.xxs)
    }
}
