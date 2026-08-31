import SwiftUI

// MARK: - Professional WorkerBindingsView

struct WorkerBindingsView: View {
    let accountId: String
    let scriptName: String
    let bindings: [WorkerBinding]
    
    @StateObject private var secretsViewModel: WorkerSecretsViewModel
    @State private var selectedTab: String = "resources" // "resources" | "variables"
    @State private var showingAddSheet = false
    @State private var showingAttachResourceSheet = false
    @State private var variableToEdit: WorkerBinding?
    @State private var itemToDelete: (name: String, isSecret: Bool)?
    @State private var bindingToDelete: WorkerBinding?
    @State private var showingDeleteAlert = false
    @State private var showingUnbindAlert = false
    
    init(accountId: String, scriptName: String, bindings: [WorkerBinding]) {
        self.accountId = accountId
        self.scriptName = scriptName
        self.bindings = bindings
        _secretsViewModel = StateObject(wrappedValue: WorkerSecretsViewModel(accountId: accountId, scriptName: scriptName))
    }
    
    private var resourceBindings: [WorkerBinding] {
        secretsViewModel.hasFetchedData ? secretsViewModel.resourceBindings : bindings.filter { $0.type != "secret_text" && $0.type != "plain_text" }
    }
    
    private var totalVariablesAndSecretsCount: Int {
        secretsViewModel.plainVariables.count + secretsViewModel.secrets.count
    }
    
    // Grouped Resources
    private var kvBindings: [WorkerBinding] { resourceBindings.filter { $0.type == "kv_namespace" } }
    private var d1Bindings: [WorkerBinding] { resourceBindings.filter { $0.type == "d1" } }
    private var r2Bindings: [WorkerBinding] { resourceBindings.filter { $0.type == "r2_bucket" } }
    private var queueBindings: [WorkerBinding] { resourceBindings.filter { $0.type == "queue" } }
    private var aiBindings: [WorkerBinding] { resourceBindings.filter { $0.type == "ai" } }
    private var otherBindings: [WorkerBinding] { resourceBindings.filter { !["kv_namespace", "d1", "r2_bucket", "queue", "ai"].contains($0.type) } }
    
    var body: some View {
        contentList
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Resource Bindings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAttachResourceSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Attach Resource")
                }
            }
        .sheet(isPresented: $showingAttachResourceSheet) {
            WorkerAttachResourceBindingSheetView(accountId: accountId, viewModel: secretsViewModel)
             .higToast()
        }
        .sheet(isPresented: $showingAddSheet) {
            WorkerAddVariableOrSecretSheetView(viewModel: secretsViewModel)
             .higToast()
        }
        .sheet(item: $variableToEdit) { v in
            WorkerEditVariableSheetView(viewModel: secretsViewModel, variable: v)
             .higToast()
        }
        .confirmationDialog("Unbind Resource", isPresented: $showingUnbindAlert, titleVisibility: .visible, presenting: bindingToDelete) { binding in
            Button("Unbind '\(binding.name)'", role: .destructive) {
                Task {
                    do {
                        try await secretsViewModel.deleteResourceBinding(name: binding.name)
                        ToastManager.shared.showSuccess("Resource Unbound", icon: "link.badge.plus")
                    } catch {
                        ToastManager.shared.showError("Failed to Unbind Resource")
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { binding in
            Text("Are you sure you want to unbind resource '\(binding.name)' from Worker '\(scriptName)'?")
        }
        .confirmationDialog("Delete Item", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: itemToDelete) { item in
            Button("Delete '\(item.name)'", role: .destructive) {
                Task {
                    do {
                        if item.isSecret {
                            try await secretsViewModel.deleteSecret(name: item.name)
                        } else {
                            try await secretsViewModel.deletePlainVariable(name: item.name)
                        }
                        ToastManager.shared.showSuccess(item.isSecret ? "Secret Deleted" : "Variable Deleted", icon: "trash.fill")
                    } catch {
                        ToastManager.shared.showError("Failed to Delete Item")
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            if item.isSecret {
                Text("Are you sure you want to delete secret '\(item.name)'?")
            } else {
                Text("Are you sure you want to delete environment variable '\(item.name)'?")
            }
        }
        .refreshable {
            await secretsViewModel.fetchSecrets()
        }
        .task {
            if !secretsViewModel.hasFetchedData {
                await secretsViewModel.fetchSecrets()
            }
        }
    }
    
    @ViewBuilder
    private var contentList: some View {
        List {
            resourcesSection
        }
        .listStyle(.insetGrouped)
        .overlay {
            if !secretsViewModel.hasFetchedData && secretsViewModel.isLoading {
                HIGContentState(.loading(message: "Loading Bindings…"))
            } else if secretsViewModel.hasFetchedData && resourceBindings.isEmpty {
                HIGContentState(
                    .empty(
                        title: "No Resource Bindings",
                        systemImage: "link.badge.plus",
                        description: "Bind Cloudflare KV, D1, R2, Queues, or AI directly to this Worker.",
                        actionTitle: "Attach Resource",
                        action: { showingAttachResourceSheet = true }
                    )
                )
            }
        }
    }
    
    @ViewBuilder
    private var resourcesSection: some View {
        if !kvBindings.isEmpty {
            Section(header: Text("KV Namespaces (\(kvBindings.count))")) {
                ForEach(kvBindings) { b in bindingRow(b) }
            }
        }
        if !d1Bindings.isEmpty {
            Section(header: Text("D1 Databases (\(d1Bindings.count))")) {
                ForEach(d1Bindings) { b in bindingRow(b) }
            }
        }
        if !r2Bindings.isEmpty {
            Section(header: Text("R2 Buckets (\(r2Bindings.count))")) {
                ForEach(r2Bindings) { b in bindingRow(b) }
            }
        }
        if !queueBindings.isEmpty {
            Section(header: Text("Queues (\(queueBindings.count))")) {
                ForEach(queueBindings) { b in bindingRow(b) }
            }
        }
        if !aiBindings.isEmpty {
            Section(header: Text("Workers AI (\(aiBindings.count))")) {
                ForEach(aiBindings) { b in bindingRow(b) }
            }
        }
        if !otherBindings.isEmpty {
            Section(header: Text("Other Bindings (\(otherBindings.count))")) {
                ForEach(otherBindings) { b in bindingRow(b) }
            }
        }
    }
    
    @ViewBuilder
    private var variablesSection: some View {
        if !secretsViewModel.plainVariables.isEmpty {
            Section(header: Text("Plaintext Variables (\(secretsViewModel.plainVariables.count))")) {
                ForEach(secretsViewModel.plainVariables) { v in
                    Button {
                        variableToEdit = v
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(v.name)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                if let text = v.text {
                                    Text(text)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            HIGFeedback.impact(.medium)
                            itemToDelete = (name: v.name, isSecret: false)
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        
        if !secretsViewModel.secrets.isEmpty {
            Section(header: Text("Encrypted Secrets (\(secretsViewModel.secrets.count))")) {
                ForEach(secretsViewModel.secrets) { s in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(s.name)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                            Text("••••••••••••••••")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        HIGBadge(.custom(color: .indigo, text: "Secret"), isCompact: true)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            HIGFeedback.impact(.medium)
                            itemToDelete = (name: s.name, isSecret: true)
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func bindingRow(_ binding: WorkerBinding) -> some View {
        HStack(spacing: 12) {
            ListRowIcon(icon: bindingIcon(for: binding.type), color: bindingColor(for: binding.type), size: 32, cornerRadius: 8)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(binding.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                let detail = bindingDetail(binding)
                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            HIGBadge(.custom(color: bindingColor(for: binding.type), text: bindingBadgeTitle(for: binding.type)), isCompact: true)
        }
        .padding(.vertical, 3)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                HIGFeedback.impact(.medium)
                bindingToDelete = binding
                showingUnbindAlert = true
            } label: {
                Label("Unbind", systemImage: "link.badge.plus")
            }
        }
    }
    
    private func bindingDetail(_ binding: WorkerBinding) -> String {
        if let ns = binding.namespaceId { return "Namespace: \(ns)" }
        if let db = binding.databaseId { return "Database: \(db)" }
        if let b = binding.bucketName { return "Bucket: \(b)" }
        if let q = binding.queueName { return "Queue: \(q)" }
        if let s = binding.service { return "Service: \(s)" }
        return ""
    }
    
    private func bindingIcon(for type: String) -> String {
        switch type.lowercased() {
        case "kv_namespace": return "key.fill"
        case "r2_bucket": return "externaldrive.fill"
        case "d1": return "cylinder.split.1x2.fill"
        case "queue": return "tray.2.fill"
        case "service": return "network"
        case "durable_object_namespace": return "cube.fill"
        case "hyperdrive": return "bolt.horizontal.fill"
        case "ai": return "brain.head.profile"
        default: return "shippingbox.fill"
        }
    }
    
    private func bindingBadgeTitle(for type: String) -> String {
        switch type.lowercased() {
        case "kv_namespace": return "KV"
        case "r2_bucket": return "R2"
        case "d1": return "D1"
        case "queue": return "Queue"
        case "service": return "Service"
        case "ai": return "AI"
        case "hyperdrive": return "Hyperdrive"
        default: return type.capitalized
        }
    }
    
    private func bindingColor(for type: String) -> Color {
        switch type.lowercased() {
        case "kv_namespace": return .purple
        case "r2_bucket": return .blue
        case "d1": return .indigo
        case "queue": return .orange
        case "service": return .teal
        case "durable_object_namespace": return .cyan
        case "hyperdrive": return .green
        case "ai": return .pink
        default: return .secondary
        }
    }
}

// MARK: - WorkerAttachResourceBindingSheetView (Inlined & Cohesive)

struct WorkerAttachResourceBindingSheetView: View {
    let accountId: String
    @ObservedObject var viewModel: WorkerSecretsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var bindingType = "kv_namespace"
    @State private var bindingName = ""
    @State private var targetIdentifier = ""
    @State private var isCustomInput = false
    
    // Existing Account Resources
    @State private var kvNamespaces: [KVNamespace] = []
    @State private var d1Databases: [D1Database] = []
    @State private var r2Buckets: [R2Bucket] = []
    @State private var queues: [CFQueue] = []
    @State private var isLoadingResources = false
    
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    let bindingTypes = [
        ("KV Namespace", "kv_namespace"),
        ("D1 Database", "d1"),
        ("R2 Bucket", "r2_bucket"),
        ("Queue", "queue"),
        ("Workers AI", "ai")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Binding Type")) {
                    Picker("Resource Type", selection: $bindingType) {
                        ForEach(bindingTypes, id: \.1) { label, value in
                            Text(verbatim: label).tag(value)
                        }
                    }
                    .onChange(of: bindingType) { newType in
                        targetIdentifier = ""
                        autoSelectFirstResource(for: newType)
                    }
                }
                
                Section(header: Text("Resource Selection")) {
                    if bindingType == "ai" {
                        HStack(spacing: 10) {
                            Image(systemName: "brain.head.profile")
                                .foregroundStyle(.pink)
                            Text("Workers AI runtime binding requires no external ID.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else if !isCustomInput && hasExistingResources(for: bindingType) {
                        Picker(resourcePickerLabel, selection: $targetIdentifier) {
                            ForEach(resourcePickerOptions(for: bindingType), id: \.id) { opt in
                                Text(opt.title).tag(opt.id)
                            }
                        }
                        .onChange(of: targetIdentifier) { newId in
                            updateBindingNameForSelectedTarget(targetId: newId, type: bindingType)
                        }
                    } else {
                        TextField(targetPlaceholder, text: $targetIdentifier)
                            .keyboardType(.asciiCapable)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
                        if hasExistingResources(for: bindingType) {
                            Button {
                                isCustomInput = false
                                autoSelectFirstResource(for: bindingType)
                            } label: {
                                Text("Choose from existing account resources")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                Section(header: Text("Binding Variable Name"), footer: Text("The JavaScript global identifier to access this resource in your code (e.g. env.\(bindingName.isEmpty ? "MY_RESOURCE" : bindingName)).")) {
                    TextField("Variable Name (e.g. MY_KV)", text: $bindingName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                
                if let err = errorMessage {
                    Section {
                        Text(verbatim: err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Attach Resource")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Attach") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            let name = bindingName.trimmingCharacters(in: .whitespaces)
                            let target = targetIdentifier.trimmingCharacters(in: .whitespaces)
                            
                            let binding = WorkerBinding(
                                name: name,
                                type: bindingType,
                                namespaceId: bindingType == "kv_namespace" ? target : nil,
                                bucketName: bindingType == "r2_bucket" ? target : nil,
                                databaseId: bindingType == "d1" ? target : nil,
                                text: nil,
                                queueName: bindingType == "queue" ? target : nil
                            )
                            
                            do {
                                try await viewModel.saveResourceBinding(binding: binding)
                                ToastManager.shared.showSuccess("Resource Attached", icon: "link.badge.plus")
                                HIGFeedback.success()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(bindingName.trimmingCharacters(in: .whitespaces).isEmpty || (bindingType != "ai" && targetIdentifier.trimmingCharacters(in: .whitespaces).isEmpty) || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .task {
                await fetchAccountResources()
            }
        }
    }
    
    private var resourcePickerLabel: String {
        switch bindingType {
        case "kv_namespace": return "KV Namespace"
        case "d1": return "D1 Database"
        case "r2_bucket": return "R2 Bucket"
        case "queue": return "Queue"
        default: return "Resource"
        }
    }
    
    private var targetPlaceholder: String {
        switch bindingType {
        case "kv_namespace": return "KV Namespace ID"
        case "d1": return "D1 Database ID"
        case "r2_bucket": return "R2 Bucket Name"
        case "queue": return "Queue Name"
        default: return "Target ID"
        }
    }
    
    private func hasExistingResources(for type: String) -> Bool {
        switch type {
        case "kv_namespace": return !kvNamespaces.isEmpty
        case "d1": return !d1Databases.isEmpty
        case "r2_bucket": return !r2Buckets.isEmpty
        case "queue": return !queues.isEmpty
        default: return false
        }
    }
    
    private func resourcePickerOptions(for type: String) -> [(id: String, title: String)] {
        switch type {
        case "kv_namespace":
            return kvNamespaces.map { (id: $0.id, title: "\($0.title) (\($0.id.prefix(8))…)") }
        case "d1":
            return d1Databases.map { (id: $0.uuid, title: "\($0.name) (\($0.uuid.prefix(8))…)") }
        case "r2_bucket":
            return r2Buckets.map { (id: $0.name, title: $0.name) }
        case "queue":
            return queues.map { (id: $0.queueName, title: $0.queueName) }
        default:
            return []
        }
    }
    
    private func autoSelectFirstResource(for type: String) {
        switch type {
        case "kv_namespace":
            if let first = kvNamespaces.first {
                targetIdentifier = first.id
                if bindingName.isEmpty { bindingName = first.title.uppercased().replacingOccurrences(of: "-", with: "_") }
            }
        case "d1":
            if let first = d1Databases.first {
                targetIdentifier = first.uuid
                if bindingName.isEmpty { bindingName = "DB" }
            }
        case "r2_bucket":
            if let first = r2Buckets.first {
                targetIdentifier = first.name
                if bindingName.isEmpty { bindingName = "\(first.name.uppercased().replacingOccurrences(of: "-", with: "_"))_BUCKET" }
            }
        case "queue":
            if let first = queues.first {
                targetIdentifier = first.queueName
                if bindingName.isEmpty { bindingName = "\(first.queueName.uppercased().replacingOccurrences(of: "-", with: "_"))_QUEUE" }
            }
        case "ai":
            if bindingName.isEmpty { bindingName = "AI" }
        default:
            break
        }
    }
    
    private func updateBindingNameForSelectedTarget(targetId: String, type: String) {
        switch type {
        case "kv_namespace":
            if let item = kvNamespaces.first(where: { $0.id == targetId }) {
                bindingName = item.title.uppercased().replacingOccurrences(of: "-", with: "_")
            }
        case "d1":
            if let item = d1Databases.first(where: { $0.uuid == targetId }) {
                bindingName = item.name.uppercased().replacingOccurrences(of: "-", with: "_")
            }
        case "r2_bucket":
            if let item = r2Buckets.first(where: { $0.name == targetId }) {
                bindingName = "\(item.name.uppercased().replacingOccurrences(of: "-", with: "_"))_BUCKET"
            }
        case "queue":
            if let item = queues.first(where: { $0.queueName == targetId }) {
                bindingName = "\(item.queueName.uppercased().replacingOccurrences(of: "-", with: "_"))_QUEUE"
            }
        default:
            break
        }
    }
    
    private func fetchAccountResources() async {
        isLoadingResources = true
        async let kvTask = try? KVService.shared.getKVNamespaces(accountId: accountId)
        async let d1Task = try? D1Service.shared.getD1Databases(accountId: accountId)
        async let r2Task = try? R2Service.shared.getR2Buckets(accountId: accountId)
        async let queueTask = try? QueueService.shared.getQueues(accountId: accountId)
        
        let (kvRes, d1Res, r2Res, queueRes) = await (kvTask, d1Task, r2Task, queueTask)
        
        await MainActor.run {
            self.kvNamespaces = kvRes ?? []
            self.d1Databases = d1Res ?? []
            self.r2Buckets = r2Res ?? []
            self.queues = queueRes ?? []
            self.isLoadingResources = false
            if targetIdentifier.isEmpty {
                autoSelectFirstResource(for: bindingType)
            }
        }
    }
}
