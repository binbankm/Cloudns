import SwiftUI

// MARK: - KVBrowserView
// Apple HIG Compliant Cloudflare Workers KV & D1 SQL Storage Hub

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
        let kvTitle = viewModel.hasFetchedData ? "KV Namespaces (\(viewModel.namespaces.count))" : "KV Namespaces"
        let d1Title = viewModel.hasFetchedData ? "D1 Databases (\(viewModel.d1Databases.count))" : "D1 Databases"
        
        VStack(spacing: 0) {
            Picker("Storage", selection: $viewModel.selectedSegment) {
                Text(kvTitle).tag(0)
                Text(d1Title).tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            .onChange(of: viewModel.selectedSegment) { _ in
                HapticManager.selection()
            }
            
            contentView
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: viewModel.selectedSegment == 0 ? "Search KV Namespaces" : "Search D1 Databases"
        )
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
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingCreateD1Sheet) {
            D1CreateDatabaseSheetView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Delete KV Namespace", isPresented: $showingDeleteKVAlert, titleVisibility: .visible, presenting: namespaceToDelete) { ns in
            Button("Delete '\(ns.title)'", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteNamespace(namespaceId: ns.id)
                        ToastManager.shared.showSuccess("KV Namespace Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                    } catch {
                        ToastManager.shared.showError("Failed to Delete Namespace")
                        HapticManager.notification(.error)
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
                        ToastManager.shared.showSuccess("D1 Database Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                    } catch {
                        ToastManager.shared.showError("Failed to Delete Database")
                        HapticManager.notification(.error)
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
            if viewModel.selectedSegment == 0 {
                if !filteredNamespaces.isEmpty {
                    Section {
                        ForEach(filteredNamespaces) { ns in
                            NavigationLink {
                                KVNamespaceKeysView(accountId: accountId, namespace: ns)
                            } label: {
                                kvRow(ns)
                            }
                            .contextMenu {
                                Button {
                                    copyToClipboard(ns.title, toast: "Namespace Title Copied")
                                } label: {
                                    Label("Copy Title", systemImage: "doc.on.doc")
                                }
                                
                                Button {
                                    copyToClipboard(ns.id, toast: "Namespace ID Copied")
                                } label: {
                                    Label("Copy ID", systemImage: "link")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    namespaceToDelete = ns
                                    showingDeleteKVAlert = true
                                } label: {
                                    Label("Delete Namespace", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    namespaceToDelete = ns
                                    showingDeleteKVAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
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
                            .contextMenu {
                                Button {
                                    copyToClipboard(db.name, toast: "Database Name Copied")
                                } label: {
                                    Label("Copy Name", systemImage: "doc.on.doc")
                                }
                                
                                Button {
                                    copyToClipboard(db.uuid, toast: "Database UUID Copied")
                                } label: {
                                    Label("Copy UUID", systemImage: "link")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    databaseToDelete = db
                                    showingDeleteD1Alert = true
                                } label: {
                                    Label("Delete Database", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    databaseToDelete = db
                                    showingDeleteD1Alert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .listState(
            isLoading: viewModel.isLoading && ((viewModel.selectedSegment == 0 && viewModel.namespaces.isEmpty) || (viewModel.selectedSegment == 1 && viewModel.d1Databases.isEmpty)),
            loadingMessage: "Loading Storage…",
            isEmpty: viewModel.hasFetchedData && ((viewModel.selectedSegment == 0 && viewModel.namespaces.isEmpty) || (viewModel.selectedSegment == 1 && viewModel.d1Databases.isEmpty)),
            emptyTitle: viewModel.selectedSegment == 0 ? "No KV Namespaces" : "No D1 Databases",
            emptySystemImage: viewModel.selectedSegment == 0 ? "key.fill" : "cylinder.split.1x2.fill",
            emptyDescription: viewModel.selectedSegment == 0 ? "You haven't created any Workers KV namespaces in this account yet." : "You haven't created any Cloudflare D1 SQL databases in this account yet.",
            emptyActionTitle: viewModel.selectedSegment == 0 ? "Create Namespace" : "Create Database",
            emptyAction: {
                if viewModel.selectedSegment == 0 {
                    showingCreateKVSheet = true
                } else {
                    showingCreateD1Sheet = true
                }
            },
            isSearchEmpty: !searchText.isEmpty && ((viewModel.selectedSegment == 0 && filteredNamespaces.isEmpty) || (viewModel.selectedSegment == 1 && filteredDatabases.isEmpty)),
            searchQuery: searchText,
            errorMessage: viewModel.errorMessage.map { LocalizedStringKey($0) },
            retryAction: { Task { await viewModel.fetchData() } }
        )
    }
    
    @ViewBuilder
    private func kvRow(_ ns: KVNamespace) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ListRowIcon(icon: "key.horizontal.fill", color: .purple)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(ns.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text(ns.id)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private func d1Row(_ db: D1Database) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ListRowIcon(icon: "cylinder.split.1x2.fill", color: .teal)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(db.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    if let version = db.version {
                        Text(version.uppercased())
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.purple.opacity(0.12)))
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
                        Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - KVCreateNamespaceSheetView (Inlined & Cohesive)

struct KVCreateNamespaceSheetView: View {
    @ObservedObject var viewModel: KVViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("MY_KV_NAMESPACE", text: $title)
                        .font(.body.monospaced())
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                } header: {
                    Text("Namespace Title")
                } footer: {
                    Text("Name your KV namespace (e.g. USER_SESSIONS).")
                }
                
                if let err = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(verbatim: err)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New KV Namespace")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            errorMessage = nil
                            do {
                                try await viewModel.createNamespace(title: title.trimmingCharacters(in: .whitespaces))
                                ToastManager.shared.showSuccess("Namespace Created", icon: "key.fill")
                                HapticManager.notification(.success)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.notification(.error)
                            }
                            isCreating = false
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}

// MARK: - D1CreateDatabaseSheetView (Inlined & Cohesive)

struct D1CreateDatabaseSheetView: View {
    @ObservedObject var viewModel: KVViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("prod-users-db", text: $name)
                        .font(.body.monospaced())
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Database Name")
                } footer: {
                    Text("Unique SQLite database name across your account.")
                }
                
                if let err = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(verbatim: err)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New D1 Database")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            errorMessage = nil
                            do {
                                try await viewModel.createDatabase(name: name.trimmingCharacters(in: .whitespaces))
                                ToastManager.shared.showSuccess("Database Created", icon: "cylinder.split.1x2.fill")
                                HapticManager.notification(.success)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.notification(.error)
                            }
                            isCreating = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}

// MARK: - KVNamespaceKeysView (Inlined & Cohesive)

struct KVNamespaceKeysView: View {
    let accountId: String
    let namespace: KVNamespace
    
    @StateObject private var viewModel: KVViewModel
    @State private var showingAddKeySheet = false
    @State private var keyToDelete: String?
    @State private var showingDeleteAlert = false
    @State private var searchText = ""
    
    init(accountId: String, namespace: KVNamespace) {
        self.accountId = accountId
        self.namespace = namespace
        _viewModel = StateObject(wrappedValue: KVViewModel(accountId: accountId))
    }
    
    private var filteredKeys: [KVKey] {
        if searchText.isEmpty { return viewModel.keys }
        return viewModel.keys.filter { $0.name.localizedStandardContains(searchText) }
    }
    
    var body: some View {
        List {
            if !filteredKeys.isEmpty {
                Section("Keys (\(filteredKeys.count))") {
                    ForEach(filteredKeys) { k in
                        NavigationLink {
                            KVKeyValueDetailView(viewModel: viewModel, namespaceId: namespace.id, keyName: k.name)
                        } label: {
                            HStack {
                                Text(k.name)
                                    .font(.body.monospaced())
                                    .foregroundStyle(.primary)
                                Spacer()
                                if let exp = k.expiration {
                                    let date = Date(timeIntervalSince1970: Double(exp))
                                    Text("Expires \(date.displayFormatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .contextMenu {
                            Button {
                                copyToClipboard(k.name, toast: "Key Name Copied")
                            } label: {
                                Label("Copy Key Name", systemImage: "doc.on.doc")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                keyToDelete = k.name
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Key", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                keyToDelete = k.name
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search Keys")
        .navigationTitle(namespace.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddKeySheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddKeySheet) {
            KVAddKeySheetView(viewModel: viewModel, namespaceId: namespace.id)
        }
        .confirmationDialog("Delete Key", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: keyToDelete) { key in
            Button("Delete '\(key)'", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteKey(namespaceId: namespace.id, key: key)
                        ToastManager.shared.showSuccess("Key Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                    } catch {
                        ToastManager.shared.showError("Failed to Delete Key")
                        HapticManager.notification(.error)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { key in
            Text("Are you sure you want to delete key '\(key)' from namespace '\(namespace.title)'?")
        }
        .refreshable {
            await viewModel.fetchKeys(for: namespace.id)
        }
        .task {
            await viewModel.fetchKeys(for: namespace.id)
        }
    }
}

// MARK: - KVKeyValueDetailView (Inlined & Cohesive)

struct KVKeyValueDetailView: View {
    @ObservedObject var viewModel: KVViewModel
    let namespaceId: String
    let keyName: String
    
    var body: some View {
        List {
            Section("Key") {
                HStack {
                    Text(keyName)
                        .font(.body.monospaced())
                    Spacer()
                    Button {
                        copyToClipboard(keyName, toast: "Key Name Copied")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Section("Value") {
                if viewModel.isValueLoading {
                    ProgressView()
                } else if let val = viewModel.selectedKeyValue {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(verbatim: val)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                        
                        Button {
                            copyToClipboard(val, toast: "Value Copied")
                        } label: {
                            Label("Copy Value", systemImage: "doc.on.doc")
                                .font(.caption.weight(.medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 2)
                } else {
                    Text("No value retrieved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(keyName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchValue(namespaceId: namespaceId, key: keyName)
        }
    }
}

// MARK: - KVAddKeySheetView (Inlined & Cohesive)

struct KVAddKeySheetView: View {
    @ObservedObject var viewModel: KVViewModel
    let namespaceId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var key = ""
    @State private var value = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Key Name") {
                    TextField("user_1001", text: $key)
                        .font(.body.monospaced())
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                
                Section("Value") {
                    TextEditor(text: $value)
                        .font(.caption.monospaced())
                        .frame(minHeight: 120)
                }
                
                if let err = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(verbatim: err)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add KV Key")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            do {
                                try await viewModel.saveKey(namespaceId: namespaceId, key: key.trimmingCharacters(in: .whitespaces), value: value)
                                ToastManager.shared.showSuccess("Key Saved", icon: "key.fill")
                                HapticManager.notification(.success)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.notification(.error)
                            }
                            isSaving = false
                        }
                    }
                    .disabled(key.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
