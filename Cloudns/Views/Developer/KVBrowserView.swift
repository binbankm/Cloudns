import SwiftUI

struct KVBrowserView: View {
    let accountId: String
    @StateObject private var viewModel: KVViewModel
    
    @State private var showingCreateKVSheet = false
    @State private var showingCreateD1Sheet = false
    @State private var namespaceToDelete: KVNamespace? = nil
    @State private var showingDeleteKVAlert = false
    @State private var databaseToDelete: D1Database? = nil
    @State private var showingDeleteD1Alert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: KVViewModel(accountId: accountId))
    }
    
    var body: some View {
        Group {
            if !viewModel.hasFetchedData {
                VStack(spacing: 0) {
                    Picker("Storage", selection: $viewModel.selectedSegment) {
                        Text("KV Namespaces").tag(0)
                        Text("D1 Databases").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGroupedBackground))
                    
                    List {
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
                    }
                    .listStyle(.insetGrouped)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("KV & D1 Storage")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                VStack(spacing: 0) {
                    Picker("Storage", selection: $viewModel.selectedSegment) {
                        Text("KV Namespaces (\(viewModel.namespaces.count))").tag(0)
                        Text("D1 Databases (\(viewModel.d1Databases.count))").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGroupedBackground))
                    
                    contentView
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("KV & D1 Storage")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
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
                .alert("Delete KV Namespace", isPresented: $showingDeleteKVAlert, presenting: namespaceToDelete) { ns in
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        Task {
                            do {
                                try await viewModel.deleteNamespace(namespaceId: ns.id)
                                ToastManager.shared.showSuccess("KV Namespace Deleted", message: ns.title)
                            } catch {
                                ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                            }
                        }
                    }
                } message: { ns in
                    Text("Are you sure you want to delete namespace '\(ns.title)'? All keys in this namespace will be permanently lost.")
                }
                .alert("Delete D1 Database", isPresented: $showingDeleteD1Alert, presenting: databaseToDelete) { db in
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        Task {
                            do {
                                try await viewModel.deleteDatabase(databaseId: db.uuid)
                                ToastManager.shared.showSuccess("D1 Database Deleted", message: db.name)
                            } catch {
                                ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                            }
                        }
                    }
                } message: { db in
                    Text("Are you sure you want to delete D1 database '\(db.name)'? This action cannot be undone.")
                }
                .refreshable {
                    await viewModel.fetchData()
                }
            }
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
                if !viewModel.namespaces.isEmpty {
                    Section {
                        ForEach(viewModel.namespaces) { ns in
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
                if !viewModel.d1Databases.isEmpty {
                    Section {
                        ForEach(viewModel.d1Databases) { db in
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
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    if let version = db.version {
                        Text(version.uppercased())
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
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

// MARK: - KV Namespace Key Management

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
        return viewModel.keys.filter { $0.name.localizedCaseInsensitiveContains(searchKey) }
    }
    
    var body: some View {
        Group {
            if !viewModel.hasFetchedData {
                List {
                    Section {
                        ForEach(KVKey.placeholders) { key in
                            keyRow(key)
                        }
                    }
                    .skeletonLoading(true)
                }
                .listStyle(.insetGrouped)
                .navigationTitle(namespace.title)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                contentView
                    .navigationTitle(namespace.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .searchable(text: $searchKey, prompt: "Search Keys")
                    .refreshable {
                        await viewModel.fetchKeys()
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
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
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchKeys()
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if !filteredKeys.isEmpty {
                Section(header: Text("Keys (\(filteredKeys.count))")) {
                    ForEach(filteredKeys) { key in
                        Button {
                            Task {
                                await viewModel.fetchValue(key: key.name)
                                showingValueSheet = true
                            }
                        } label: {
                            keyRow(key)
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
        .overlay {
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
                            icon: "tray",
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
    
    @ViewBuilder
    private func keyRow(_ key: KVKey) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(key.name)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.primary)
                
                if let exp = key.expiration {
                    Text("Expires: \(exp)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color(.tertiaryLabel))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Sheets

struct KVCreateNamespaceSheetView: View {
    @ObservedObject var viewModel: KVViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Namespace Information"), footer: Text("Namespaces are globally distributed Key-Value stores.")) {
                    TextField("Title (e.g. AUTH_SESSIONS)", text: $title)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New KV Namespace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            errorMessage = nil
                            do {
                                try await viewModel.createNamespace(title: title.trimmingCharacters(in: .whitespacesAndNewlines))
                                ToastManager.shared.showSuccess("Namespace Created", message: title)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isCreating = false
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                }
            }
            .toastContainer()
        }
    }
}

struct D1CreateDatabaseSheetView: View {
    @ObservedObject var viewModel: KVViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Database Information"), footer: Text("D1 is Cloudflare's native serverless SQL database powered by SQLite.")) {
                    TextField("Database Name (e.g. prod-db)", text: $name)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New D1 Database")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            errorMessage = nil
                            do {
                                try await viewModel.createDatabase(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
                                ToastManager.shared.showSuccess("Database Created", message: name)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isCreating = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                }
            }
            .toastContainer()
        }
    }
}

struct KVAddKeySheetView: View {
    @ObservedObject var viewModel: KVNamespaceDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var key: String = ""
    @State private var value: String = ""
    @State private var expirationTtl: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Key Details")) {
                    TextField("Key (e.g. user:12345:profile)", text: $key)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("Expiration TTL (seconds, optional)", text: $expirationTtl)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Value")) {
                    TextEditor(text: $value)
                        .frame(minHeight: 120)
                        .font(.body.monospaced())
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Key / Value")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            do {
                                let ttl = Int(expirationTtl)
                                try await viewModel.saveKey(key: key.trimmingCharacters(in: .whitespacesAndNewlines), value: value, ttl: ttl)
                                ToastManager.shared.showSuccess("Key Saved", message: key)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isSaving = false
                        }
                    }
                    .disabled(key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .toastContainer()
        }
    }
}

struct KVValueSheetView: View {
    let keyName: String
    let valueText: String
    let isLoading: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("KEY:")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(keyName)
                            .font(.caption.monospaced())
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView("Loading value...")
                            Spacer()
                        }
                        .padding(.vertical, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("VALUE CONTENT")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = valueText
                                    HapticManager.impact(.light)
                                    ToastManager.shared.showCopied("Value copied")
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .font(.caption)
                                }
                            }
                            
                            Text(valueText)
                                .font(.footnote.monospaced())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("KV Value Inspector")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .toastContainer()
        }
    }
}
