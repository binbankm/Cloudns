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
        VStack(spacing: 0) {
            Picker("Storage", selection: $viewModel.selectedSegment) {
                Text("KV Namespaces (\(viewModel.namespaces.count))").tag(0)
                Text("D1 Databases (\(viewModel.d1Databases.count))").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGroupedBackground))
            
            contentView
        }
        .background(Color(UIColor.systemGroupedBackground))
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
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchData()
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                EmptyStateView.error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task { await viewModel.fetchData() }
                    }
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else if viewModel.selectedSegment == 0 {
                if viewModel.namespaces.isEmpty {
                    EmptyStateView(
                        icon: "key.fill",
                        title: "No KV Namespaces",
                        message: "You haven't created any Workers KV namespaces in this account yet.",
                        actionTitle: "Create Namespace",
                        action: { showingCreateKVSheet = true }
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } else {
                    ForEach(viewModel.namespaces) { ns in
                        NavigationLink {
                            KVNamespaceKeysView(accountId: accountId, namespace: ns)
                        } label: {
                            HStack(alignment: .center, spacing: 14) {
                                Image(systemName: "key.horizontal.fill")
                                    .font(.body)
                                    .foregroundColor(.purple)
                                    .frame(width: 32, height: 32)
                                    .background(Color.purple.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(ns.title)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Text(ns.id)
                                        .font(.caption.monospacedDigit())
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                namespaceToDelete = ns
                                showingDeleteKVAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            } else {
                if viewModel.d1Databases.isEmpty {
                    EmptyStateView(
                        icon: "cylinder.split.1x2.fill",
                        title: "No D1 Databases",
                        message: "You haven't created any Cloudflare D1 SQL databases in this account yet.",
                        actionTitle: "Create Database",
                        action: { showingCreateD1Sheet = true }
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } else {
                    ForEach(viewModel.d1Databases) { db in
                        NavigationLink {
                            D1ConsoleView(accountId: accountId, database: db)
                        } label: {
                            HStack(alignment: .center, spacing: 14) {
                                Image(systemName: "cylinder.split.1x2.fill")
                                    .font(.body)
                                    .foregroundColor(.purple)
                                    .frame(width: 32, height: 32)
                                    .background(Color.purple.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(db.name)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        if let version = db.version {
                                            Text(version.uppercased())
                                                .font(.caption2.weight(.medium))
                                                .foregroundColor(.purple)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 1)
                                                .background(Color.purple.opacity(0.12))
                                                .cornerRadius(4)
                                        }
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Text(db.uuid)
                                            .font(.caption2.monospacedDigit())
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                        
                                        if let size = db.fileSize {
                                            Text("·")
                                                .foregroundColor(.secondary)
                                            Text(formatBytes(size))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 3)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
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
        .listStyle(.insetGrouped)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024.0)
        } else {
            return String(format: "%.2f MB", Double(bytes) / (1024.0 * 1024.0))
        }
    }
}

// MARK: - KV Create Sheet

struct KVCreateNamespaceSheetView: View {
    @ObservedObject var viewModel: KVViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var namespaceTitle = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Namespace Details")) {
                    TextField("Namespace Title (e.g. MY_KV)", text: $namespaceTitle)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
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
                                try await viewModel.createNamespace(title: namespaceTitle.trimmingCharacters(in: .whitespaces))
                                ToastManager.shared.showSuccess("KV Storage", message: "Namespace created successfully")
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isCreating = false
                        }
                    }
                    .disabled(namespaceTitle.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .toastContainer()
        }
    }
}

// MARK: - D1 Create Sheet

struct D1CreateDatabaseSheetView: View {
    @ObservedObject var viewModel: KVViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var databaseName = ""
    @State private var selectedLocation = "auto"
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    let locations = [
        ("auto", "Automatic (Default)"),
        ("wnam", "Western North America"),
        ("enam", "Eastern North America"),
        ("weur", "Western Europe"),
        ("eeur", "Eastern Europe"),
        ("apac", "Asia-Pacific")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Database Details")) {
                    TextField("Database Name", text: $databaseName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    Picker("Primary Location", selection: $selectedLocation) {
                        ForEach(locations, id: \.0) { loc in
                            Text(loc.1).tag(loc.0)
                        }
                    }
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
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
                                let loc = selectedLocation == "auto" ? nil : selectedLocation
                                try await viewModel.createDatabase(name: databaseName.trimmingCharacters(in: .whitespaces), locationHint: loc)
                                ToastManager.shared.showSuccess("D1 SQL", message: "Database created successfully")
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isCreating = false
                        }
                    }
                    .disabled(databaseName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .toastContainer()
        }
    }
}

// MARK: - KV Keys Viewer Subview (Isolated ViewModel for Zero Stale Flash)

struct KVNamespaceKeysView: View {
    let accountId: String
    let namespace: KVNamespace
    @StateObject private var viewModel: KVNamespaceDetailViewModel
    @State private var searchKey = ""
    @State private var showingValueSheet = false
    @State private var showingAddSheet = false
    
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
        contentView
            .navigationTitle(namespace.title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchKey, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Keys")
            .refreshable {
                await viewModel.fetchKeys()
            }
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchKeys()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
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
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                EmptyStateView.error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task { await viewModel.fetchKeys() }
                    }
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else if viewModel.keys.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "Empty Namespace",
                    message: "This KV namespace currently contains no keys.",
                    actionTitle: "Add Key",
                    action: { showingAddSheet = true }
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else if filteredKeys.isEmpty {
                EmptyStateView.search(query: searchKey) {
                    searchKey = ""
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else {
                ForEach(filteredKeys) { key in
                    Button {
                        Task {
                            await viewModel.fetchValue(key: key.name)
                            showingValueSheet = true
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(key.name)
                                    .font(.body.monospacedDigit())
                                    .foregroundColor(.primary)
                                
                                if let exp = key.expiration {
                                    Text("Expires: \(exp)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                        .padding(.vertical, 3)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
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
        .listStyle(.insetGrouped)
    }
}

// MARK: - Add / Edit Key Sheet

struct KVAddKeySheetView: View {
    @ObservedObject var viewModel: KVNamespaceDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var keyName = ""
    @State private var keyValue = ""
    @State private var ttlString = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Key Details")) {
                    TextField("Key Name", text: $keyName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Expiration TTL (Seconds, Optional)", text: $ttlString)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Value")) {
                    TextEditor(text: $keyValue)
                        .font(.body.monospacedDigit())
                        .frame(minHeight: 100)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add / Edit Key")
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
                                let ttl = Int(ttlString.trimmingCharacters(in: .whitespaces))
                                try await viewModel.saveKey(key: keyName.trimmingCharacters(in: .whitespaces), value: keyValue, ttl: ttl)
                                ToastManager.shared.showSuccess("KV Storage", message: "Key saved successfully")
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isSaving = false
                        }
                    }
                    .disabled(keyName.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .toastContainer()
        }
    }
}

// MARK: - Value Inspector Sheet

struct KVValueSheetView: View {
    let keyName: String
    let valueText: String
    let isLoading: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        Text(valueText)
                            .font(.body.monospacedDigit())
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .textSelection(.enabled)
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(keyName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        UIPasteboard.general.string = valueText
                        ToastManager.shared.showCopied("Value copied")
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }
            .toastContainer()
        }
    }
}
