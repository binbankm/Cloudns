import SwiftUI

struct KVBrowserView: View {
    let accountId: String
    @StateObject private var viewModel: KVViewModel
    
    @State private var searchText = ""
    @State private var showingCreateKVSheet = false
    @State private var showingCreateD1Sheet = false
    @State private var namespaceToDelete: KVNamespace?
    @State private var showingDeleteKVAlert = false
    @State private var databaseToDelete: D1Database?
    @State private var showingDeleteD1Alert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: KVViewModel(accountId: accountId))
    }
    
    private var filteredNamespaces: [KVNamespace] {
        if searchText.isEmpty { return viewModel.namespaces }
        return viewModel.namespaces.filter {
            $0.title.localizedStandardContains(searchText) ||
            $0.id.localizedStandardContains(searchText)
        }
    }
    
    private var filteredDatabases: [D1Database] {
        if searchText.isEmpty { return viewModel.d1Databases }
        return viewModel.d1Databases.filter {
            $0.name.localizedStandardContains(searchText) ||
            $0.uuid.localizedStandardContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $searchText,
                prompt: viewModel.selectedSegment == 0 ? "Search KV Namespaces" : "Search D1 Databases"
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(Color(.systemGroupedBackground))
            
            Picker("Storage", selection: $viewModel.selectedSegment) {
                Text(viewModel.hasFetchedData ? "KV Namespaces (\(viewModel.namespaces.count))" : "KV Namespaces").tag(0)
                Text(viewModel.hasFetchedData ? "D1 Databases (\(viewModel.d1Databases.count))" : "D1 Databases").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            
            contentView
                .centerConstrainedWidth(maxWidth: 840)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("KV & D1")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if viewModel.selectedSegment == 0 {
                        showingCreateKVSheet = true
                    } else {
                        showingCreateD1Sheet = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create Storage")
            }
        }
        .sheet(isPresented: $showingCreateKVSheet) {
            KVCreateNamespaceSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingCreateD1Sheet) {
            D1CreateDatabaseSheetView(viewModel: viewModel)
        }
        .confirmationDialog("Delete KV Namespace", isPresented: $showingDeleteKVAlert, titleVisibility: .visible, presenting: namespaceToDelete) { ns in
            Button("Delete '\(ns.title)'", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteNamespace(namespaceId: ns.id)
                        ToastManager.shared.showSuccess("KV Namespace Deleted", message: ns.title)
                    } catch {
                        ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { ns in
            Text("Are you sure you want to delete namespace '\(ns.title)'? All keys in this namespace will be permanently lost.")
        }
        .confirmationDialog("Delete D1 Database", isPresented: $showingDeleteD1Alert, titleVisibility: .visible, presenting: databaseToDelete) { db in
            Button("Delete '\(db.name)'", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteDatabase(databaseId: db.uuid)
                        ToastManager.shared.showSuccess("D1 Database Deleted", message: db.name)
                    } catch {
                        ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { db in
            Text("Are you sure you want to delete database '\(db.name)'? All tables and data will be permanently dropped.")
        }
        .refreshable {
            await viewModel.fetchData()
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchData()
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    if viewModel.selectedSegment == 0 {
                        ForEach(KVNamespace.placeholders) { ns in
                            kvRow(ns)
                        }
                    } else {
                        ForEach(D1Database.placeholders) { db in
                            d1Row(db)
                        }
                    }
                }
                .skeletonLoading(true)
            } else if viewModel.selectedSegment == 0 {
                if !filteredNamespaces.isEmpty {
                    Section {
                        ForEach(filteredNamespaces) { ns in
                            NavigationLink {
                                KVNamespaceKeysView(accountId: accountId, namespace: ns)
                            } label: {
                                kvRow(ns)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    namespaceToDelete = ns
                                    showingDeleteKVAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            } else {
                if !filteredDatabases.isEmpty {
                    Section {
                        ForEach(filteredDatabases) { db in
                            NavigationLink {
                                D1ConsoleView(accountId: accountId, database: db)
                            } label: {
                                d1Row(db)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    databaseToDelete = db
                                    showingDeleteD1Alert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.namespaces.isEmpty && viewModel.d1Databases.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchData() } }
                        )
                    )
                } else if viewModel.selectedSegment == 0 && viewModel.namespaces.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "key.fill",
                            title: "No KV Namespaces",
                            message: "You haven't created any Workers KV namespaces in this account yet.",
                            actionTitle: "Create Namespace",
                            action: { showingCreateKVSheet = true }
                        )
                    )
                } else if viewModel.selectedSegment == 1 && viewModel.d1Databases.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "cylinder.split.1x2.fill",
                            title: "No D1 Databases",
                            message: "You haven't created any Cloudflare D1 SQL databases in this account yet.",
                            actionTitle: "Create Database",
                            action: { showingCreateD1Sheet = true }
                        )
                    )
                } else if !searchText.isEmpty && ((viewModel.selectedSegment == 0 && filteredNamespaces.isEmpty) || (viewModel.selectedSegment == 1 && filteredDatabases.isEmpty)) {
                    StateOverlayView(
                        state: .search(
                            query: searchText,
                            clearAction: { searchText = "" }
                        )
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func kvRow(_ ns: KVNamespace) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "key.horizontal.fill")
                .font(.body)
                .foregroundStyle(.purple)
                .frame(width: 32, height: 32)
                .background(Color.purple.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(ns.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Text(ns.id)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("KV Namespace \(ns.title), ID \(ns.id)")
    }
    
    @ViewBuilder
    private func d1Row(_ db: D1Database) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "cylinder.split.1x2.fill")
                .font(.body)
                .foregroundStyle(.purple)
                .frame(width: 32, height: 32)
                .background(Color.purple.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(db.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    if let version = db.version {
                        CloudnsBadge(.custom(color: .purple, text: version.uppercased()), isCompact: true)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(db.uuid)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    if let size = db.fileSize {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(formatBytes(size))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 3)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let b = Double(bytes)
        if b < 1024 { return "\(bytes) B" }
        let kb = b / 1024.0
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024.0
        return String(format: "%.2f MB", mb)
    }
}
