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
        Group {
            if !viewModel.hasFetchedData {
                List {
                    Section(header: Text("Namespaces")) {
                        ForEach(DurableObjectNamespace.placeholders) { ns in
                            nsRow(ns)
                                .skeletonLoading(true)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Durable Objects")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                List {
                    if !viewModel.filteredNamespaces.isEmpty {
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
                .overlay {
                    if let err = viewModel.errorMessage, viewModel.namespaces.isEmpty {
                        StateOverlayView(
                            state: .error(
                                message: LocalizedStringKey(err),
                                retryAction: { Task { await viewModel.fetchNamespaces() } }
                            )
                        )
                    } else if viewModel.namespaces.isEmpty {
                        StateOverlayView(
                            state: .empty(
                                icon: "cube.fill",
                                title: "No Durable Objects",
                                message: "Durable Objects namespaces are created via Wrangler migrations inside your Worker code.",
                                actionTitle: "Refresh",
                                action: { Task { await viewModel.fetchNamespaces() } }
                            )
                        )
                    } else if viewModel.filteredNamespaces.isEmpty && !viewModel.searchText.isEmpty {
                        StateOverlayView(
                            state: .search(
                                query: viewModel.searchText,
                                clearAction: { viewModel.searchText = "" }
                            )
                        )
                    }
                }
                .navigationTitle("Durable Objects")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $viewModel.searchText, prompt: "Search Namespaces")
                .refreshable {
                    await viewModel.fetchNamespaces()
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.hasFetchedData)
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
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(ns.name)
                    .font(.body.weight(.medium))
                
                if let script = ns.script {
                    Text("Worker: \(script)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(String(ns.id.prefix(8)))
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct DurableObjectNamespaceDetailView: View {
    let accountId: String
    let namespace: DurableObjectNamespace
    
    @State private var objects: [DurableObjectInstance] = []
    @State private var nextCursor: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            Section(header: Text("Namespace Metadata")) {
                HStack {
                    Text("Namespace Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(namespace.name)
                        .font(.body.weight(.medium))
                }
                
                HStack {
                    Text("Namespace ID")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(namespace.id)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                
                if let script = namespace.script {
                    HStack {
                        Text("Bound Script")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(script)
                            .font(.subheadline)
                    }
                }
                
                if let cls = namespace.class {
                    HStack {
                        Text("Exported Class")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(cls)
                            .font(.subheadline)
                    }
                }
            }
            
            Section(header: Text("Active Instances (\(objects.count))"), footer: Text("Instances are spun up on-demand at the edge nearest to incoming coordination requests.")) {
                if isLoading && objects.isEmpty {
                    ProgressView()
                } else if let err = errorMessage, objects.isEmpty {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if objects.isEmpty {
                    Text("No active instances discovered in this namespace.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(objects) { obj in
                        HStack {
                            Image(systemName: "circle.circle.fill")
                                .foregroundStyle(obj.hasStoredData == true ? .green : .secondary)
                                .font(.caption)
                                .accessibilityHidden(true)
                            Text(obj.id)
                                .font(.caption.monospaced())
                            Spacer()
                            if obj.hasStoredData == true {
                                Text("Stored Data")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(namespace.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchObjects()
        }
    }
    
    private func fetchObjects() async {
        isLoading = true
        errorMessage = nil
        do {
            let res = try await CloudflareAPIClient.shared.listDOObjects(accountId: accountId, namespaceId: namespace.id)
            self.objects = res.items
            self.nextCursor = res.cursor
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
