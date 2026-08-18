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
                Section(header: Text("Namespaces")) {
                    ForEach(DurableObjectNamespace.placeholders) { placeholder in
                        nsRow(placeholder)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
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
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("Durable Objects")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Namespaces")
        .refreshable {
            await viewModel.fetchNamespaces()
        }
        .overlay {
            if viewModel.hasFetchedData {
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
                .clipShape(RoundedRectangle(cornerRadius: 8))
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
            Section(header: Text("Namespace Details")) {
                HStack {
                    Text("Namespace ID")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(namespace.id)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
                
                if let scr = namespace.script {
                    HStack {
                        Text("Bound Worker Script")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(scr)
                            .font(.subheadline.monospaced())
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
                    ForEach(DurableObjectInstance.placeholders) { placeholder in
                        instanceRow(placeholder)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
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
                        instanceRow(obj)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle(namespace.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await fetchObjects()
        }
        .task {
            await fetchObjects()
        }
    }
    
    @ViewBuilder
    private func instanceRow(_ obj: DurableObjectInstance) -> some View {
        HStack {
            Image(systemName: "circle.circle.fill")
                .foregroundStyle(obj.hasStoredData == true ? .green : .secondary)
                .font(.caption)
                .accessibilityHidden(true)
            
            Text(obj.id)
                .font(.caption.monospaced())
                .foregroundStyle(.primary)
            
            Spacer()
            
            if obj.hasStoredData == true {
                CloudnsBadge(.active("Persistent Data"), isCompact: true)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func fetchObjects() async {
        isLoading = true
        errorMessage = nil
        do {
            let res = try await DurableObjectService.shared.listDOObjects(accountId: accountId, namespaceId: namespace.id)
            self.objects = res.items
            self.nextCursor = res.cursor
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
