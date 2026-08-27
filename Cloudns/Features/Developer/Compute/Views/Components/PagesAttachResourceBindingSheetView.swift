import SwiftUI

// MARK: - PagesAttachResourceBindingSheetView

struct PagesAttachResourceBindingSheetView: View {
    // MARK: - Properties
    let accountId: String
    let projectName: String
    let initialEnvironment: String
    let existingKV: [String: PagesKVBinding]
    let existingD1: [String: PagesD1Binding]
    let existingR2: [String: PagesR2Binding]
    let existingAI: [String: PagesAIBinding]
    let onSaved: (_ environment: String, _ kv: [String: PagesKVBinding], _ d1: [String: PagesD1Binding], _ r2: [String: PagesR2Binding], _ ai: [String: PagesAIBinding]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var environment: String
    @State private var bindingName: String = ""
    @State private var bindingType: String = "kv_namespace"
    
    // Selection state
    @State private var selectedKVId: String = ""
    @State private var selectedD1Id: String = ""
    @State private var selectedR2Bucket: String = ""
    
    // Loaded Resources
    @State private var kvNamespaces: [KVNamespace] = []
    @State private var d1Databases: [D1Database] = []
    @State private var r2Buckets: [R2Bucket] = []
    
    @State private var isLoadingResources = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private let availableTypes: [(id: String, name: String, icon: String, color: Color)] = [
        ("kv_namespace", "KV Namespace", "key.fill", .purple),
        ("d1", "D1 Database", "cylinder.split.1x2.fill", .indigo),
        ("r2_bucket", "R2 Bucket", "externaldrive.fill", .blue),
        ("ai", "Workers AI", "brain.head.profile", .pink)
    ]
    
    init(
        accountId: String,
        projectName: String,
        environment: String,
        existingKV: [String: PagesKVBinding],
        existingD1: [String: PagesD1Binding],
        existingR2: [String: PagesR2Binding],
        existingAI: [String: PagesAIBinding],
        onSaved: @escaping (_ environment: String, _ kv: [String: PagesKVBinding], _ d1: [String: PagesD1Binding], _ r2: [String: PagesR2Binding], _ ai: [String: PagesAIBinding]) -> Void
    ) {
        self.accountId = accountId
        self.projectName = projectName
        self.initialEnvironment = environment
        self.existingKV = existingKV
        self.existingD1 = existingD1
        self.existingR2 = existingR2
        self.existingAI = existingAI
        self.onSaved = onSaved
        _environment = State(initialValue: environment)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Environment")) {
                    Picker("Target Environment", selection: $environment) {
                        Text("Production").tag("production")
                        Text("Preview").tag("preview")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Resource Type")) {
                    Picker("Type", selection: $bindingType) {
                        ForEach(availableTypes, id: \.id) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundStyle(type.color)
                                Text(type.name)
                            }
                            .tag(type.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: bindingType) { newType in
                        HapticManager.selection()
                        if bindingName.isEmpty || isDefaultBindingName(bindingName) {
                            bindingName = defaultBindingName(for: newType)
                        }
                    }
                }
                
                Section(header: Text("Binding Variable Name"), footer: Text("The variable name accessible inside Pages Functions (e.g. context.env.\(bindingName.isEmpty ? "MY_RESOURCE" : bindingName)).")) {
                    TextField("Variable Name (e.g. \(defaultBindingName(for: bindingType)))", text: $bindingName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Target Resource")) {
                    if isLoadingResources {
                        HStack {
                            ProgressView().scaleEffect(0.8)
                            Text("Loading resources...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    } else {
                        resourceSelector
                    }
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Pages Binding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bind") {
                        Task { await saveBinding() }
                    }
                    .disabled(!isValid || isSaving)
                    .overlay {
                        if isSaving { ProgressView() }
                    }
                }
            }
            .interactiveDismissDisabled(isSaving)
            .task {
                await loadAccountResources()
                if bindingName.isEmpty {
                    bindingName = defaultBindingName(for: bindingType)
                }
            }
        }
    }
    
    @ViewBuilder
    // MARK: - Private Views
    private var resourceSelector: some View {
        switch bindingType {
        case "kv_namespace":
            if kvNamespaces.isEmpty {
                Text("No KV namespaces found in this account.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    Text("KV Namespace")
                        .foregroundStyle(.primary)
                    Spacer()
                    Picker(selection: $selectedKVId) {
                        ForEach(kvNamespaces) { ns in
                            Text(ns.title).tag(ns.id)
                        }
                    } label: {
                        EmptyView()
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                }
            }
        case "d1":
            if d1Databases.isEmpty {
                Text("No D1 databases found in this account.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    Text("D1 Database")
                        .foregroundStyle(.primary)
                    Spacer()
                    Picker(selection: $selectedD1Id) {
                        ForEach(d1Databases) { db in
                            Text(db.name).tag(db.uuid)
                        }
                    } label: {
                        EmptyView()
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                }
            }
        case "r2_bucket":
            if r2Buckets.isEmpty {
                Text("No R2 buckets found in this account.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    Text("R2 Bucket")
                        .foregroundStyle(.primary)
                    Spacer()
                    Picker(selection: $selectedR2Bucket) {
                        ForEach(r2Buckets) { b in
                            Text(b.name).tag(b.name)
                        }
                    } label: {
                        EmptyView()
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                }
            }
        case "ai":
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.pink)
                Text("Workers AI inference binding for Pages Functions.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        default:
            EmptyView()
        }
    }
    
    private var isValid: Bool {
        let cleanName = bindingName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return false }
        switch bindingType {
        case "kv_namespace": return !selectedKVId.isEmpty
        case "d1": return !selectedD1Id.isEmpty
        case "r2_bucket": return !selectedR2Bucket.isEmpty
        case "ai": return true
        default: return false
        }
    }
    
    // MARK: - Actions
    private func defaultBindingName(for type: String) -> String {
        switch type {
        case "kv_namespace": return "MY_KV"
        case "d1": return "DB"
        case "r2_bucket": return "BUCKET"
        case "ai": return "AI"
        default: return "RESOURCE"
        }
    }
    
    private func isDefaultBindingName(_ name: String) -> Bool {
        ["MY_KV", "DB", "BUCKET", "AI", "RESOURCE"].contains(name)
    }
    
    private func loadAccountResources() async {
        isLoadingResources = true
        async let kvTask = try? KVService.shared.getKVNamespaces(accountId: accountId)
        async let d1Task = try? D1Service.shared.getD1Databases(accountId: accountId)
        async let r2Task = try? R2Service.shared.getR2Buckets(accountId: accountId)
        
        let (kvs, d1s, r2s) = await (kvTask, d1Task, r2Task)
        self.kvNamespaces = kvs ?? []
        self.d1Databases = d1s ?? []
        self.r2Buckets = r2s ?? []
        
        if let firstKV = kvNamespaces.first { selectedKVId = firstKV.id }
        if let firstD1 = d1Databases.first { selectedD1Id = firstD1.uuid }
        if let firstR2 = r2Buckets.first { selectedR2Bucket = firstR2.name }
        
        isLoadingResources = false
    }
    
    private func saveBinding() async {
        isSaving = true
        errorMessage = nil
        HapticManager.impact(.medium)
        
        let cleanName = bindingName.trimmingCharacters(in: .whitespacesAndNewlines)
        var updatedKV = existingKV
        var updatedD1 = existingD1
        var updatedR2 = existingR2
        var updatedAI = existingAI
        
        switch bindingType {
        case "kv_namespace":
            updatedKV[cleanName] = PagesKVBinding(namespaceId: selectedKVId)
        case "d1":
            updatedD1[cleanName] = PagesD1Binding(id: selectedD1Id)
        case "r2_bucket":
            updatedR2[cleanName] = PagesR2Binding(name: selectedR2Bucket)
        case "ai":
            updatedAI[cleanName] = PagesAIBinding(projectId: "")
        default:
            break
        }
        
        do {
            try await PagesService.shared.updatePagesResourceBindings(
                accountId: accountId,
                projectName: projectName,
                environment: environment,
                kvNamespaces: updatedKV,
                d1Databases: updatedD1,
                r2Buckets: updatedR2,
                aiBindings: updatedAI
            )
            HapticManager.notification(.success)
            CloudnsToastManager.shared.showSuccess("Resource Bound", message: "\(cleanName) (\(environment.capitalized))")
            onSaved(environment, updatedKV, updatedD1, updatedR2, updatedAI)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
