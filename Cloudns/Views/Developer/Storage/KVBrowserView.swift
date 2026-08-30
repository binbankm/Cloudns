import SwiftUI

// MARK: - KVBrowserView

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
                HIGFeedback.selection()
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
             .higToast()
        }
        .sheet(isPresented: $showingCreateD1Sheet) {
            D1CreateDatabaseSheetView(viewModel: viewModel)
             .higToast()
        }
        .confirmationDialog("Delete KV Namespace", isPresented: $showingDeleteKVAlert, titleVisibility: .visible, presenting: namespaceToDelete) { ns in
            Button("Delete '\(ns.title)'", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteNamespace(namespaceId: ns.id)
                        ToastManager.shared.showSuccess("KV Namespace Deleted", icon: "trash.fill")
                    } catch {
                        ToastManager.shared.showError("Failed to delete namespace")
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
                    } catch {
                        ToastManager.shared.showError("Failed to delete database")
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HIGFeedback.impact(.medium)
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
                                    HIGFeedback.impact(.medium)
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
            if viewModel.isLoading && ((viewModel.selectedSegment == 0 && viewModel.namespaces.isEmpty) || (viewModel.selectedSegment == 1 && viewModel.d1Databases.isEmpty)) {
                HIGContentState(.loading(message: "Loading Storage..."))
            } else if let errorMessage = viewModel.errorMessage, viewModel.namespaces.isEmpty && viewModel.d1Databases.isEmpty {
                HIGContentState(
                    .error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: { Task { await viewModel.fetchData() } }
                    )
                )
            } else if viewModel.hasFetchedData {
                if viewModel.selectedSegment == 0 && viewModel.namespaces.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No KV Namespaces",
                            systemImage: "key.fill",
                            description: "You haven't created any Workers KV namespaces in this account yet.",
                            actionTitle: "Create Namespace",
                            action: { showingCreateKVSheet = true }
                        )
                    )
                } else if viewModel.selectedSegment == 1 && viewModel.d1Databases.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No D1 Databases",
                            systemImage: "cylinder.split.1x2.fill",
                            description: "You haven't created any Cloudflare D1 SQL databases in this account yet.",
                            actionTitle: "Create Database",
                            action: { showingCreateD1Sheet = true }
                        )
                    )
                } else if !searchText.isEmpty && ((viewModel.selectedSegment == 0 && filteredNamespaces.isEmpty) || (viewModel.selectedSegment == 1 && filteredDatabases.isEmpty)) {
                    HIGContentState(.search(query: searchText))
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
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(ns.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text(ns.id)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }
    
    @ViewBuilder
    private func d1Row(_ db: D1Database) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "cylinder.split.1x2.fill")
                .font(.body)
                .foregroundStyle(.purple)
                .frame(width: 32, height: 32)
                .background(Color.purple.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(db.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    if let version = db.version {
                        HIGBadge(.custom(color: .purple, text: version.uppercased()), isCompact: true)
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
        .padding(.vertical, 3)
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
                Section(header: Text("Namespace Title"), footer: Text("Name your KV namespace (e.g. USER_SESSIONS).")) {
                    TextField("MY_KV_NAMESPACE", text: $title)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
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
                                HIGFeedback.success()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
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
                Section(header: Text("Database Name"), footer: Text("Unique SQLite database name across your account.")) {
                    TextField("prod-users-db", text: $name)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
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
                                HIGFeedback.success()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
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
                Section(header: Text("Keys (\(filteredKeys.count))")) {
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
                                    Text("Expires \(DateFormatters.formatISO8601ToDisplay(String(exp), style: DateFormatters.dateOnly))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                keyToDelete = k.name
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
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
             .higToast()
        }
        .confirmationDialog("Delete Key", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: keyToDelete) { key in
            Button("Delete '\(key)'", role: .destructive) {
                Task {
                    try? await viewModel.deleteKey(namespaceId: namespace.id, key: key)
                    HIGFeedback.success()
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
            Section(header: Text("Key")) {
                Text(keyName)
                    .font(.body.monospaced())
            }
            
            Section(header: Text("Value")) {
                if viewModel.isValueLoading {
                    ProgressView()
                } else if let val = viewModel.selectedKeyValue {
                    Text(val)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
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
                Section(header: Text("Key Name")) {
                    TextField("user_1001", text: $key)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Value")) {
                    TextEditor(text: $value)
                        .font(.caption.monospaced())
                        .frame(minHeight: 120)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
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
                                HIGFeedback.success()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
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
