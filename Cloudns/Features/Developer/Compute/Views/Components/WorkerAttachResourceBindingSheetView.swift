import SwiftUI

// MARK: - WorkerAttachResourceBindingSheetView

struct WorkerAttachResourceBindingSheetView: View {
    // MARK: - Properties
    let accountId: String
    @ObservedObject var viewModel: WorkerSecretsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var bindingName: String = ""
    @State private var bindingType: String = "kv_namespace"
    
    // Resource Selection State
    @State private var selectedKVId: String = ""
    @State private var selectedD1Id: String = ""
    @State private var selectedD1Name: String = ""
    @State private var selectedR2Bucket: String = ""
    @State private var selectedQueueName: String = ""
    @State private var serviceName: String = ""
    @State private var serviceEnvironment: String = "production"
    
    // Loaded Resources
    @State private var kvNamespaces: [KVNamespace] = []
    @State private var d1Databases: [D1Database] = []
    @State private var r2Buckets: [R2Bucket] = []
    @State private var queues: [CFQueue] = []
    
    @State private var isLoadingResources = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private let availableTypes: [(id: String, name: String, icon: String, color: Color)] = [
        ("kv_namespace", "KV Namespace", "key.fill", .purple),
        ("d1", "D1 Database", "cylinder.split.1x2.fill", .indigo),
        ("r2_bucket", "R2 Bucket", "externaldrive.fill", .blue),
        ("queue", "Queue", "tray.2.fill", .purple),
        ("ai", "Workers AI", "brain.head.profile", .orange),
        ("service", "Service Binding", "network", .teal)
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 1. Binding Type Picker
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
                
                // MARK: - 2. Variable Name
                Section(header: Text("Binding Variable Name"), footer: Text("The variable name used in Worker code (e.g. env.\(bindingName.isEmpty ? "MY_RESOURCE" : bindingName)).")) {
                    TextField("Variable Name (e.g. \(defaultBindingName(for: bindingType)))", text: $bindingName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                
                // MARK: - 3. Target Resource Selection
                Section(header: Text("Target Resource")) {
                    if isLoadingResources {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading available resources...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, CloudnsSpacing.xs)
                    } else {
                        resourceSelector
                    }
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(CloudnsColor.danger)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Resource Binding")
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
    
    // MARK: - Resource Selector View
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
            
        case "queue":
            if queues.isEmpty {
                Text("No queues found in this account.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    Text("Queue")
                        .foregroundStyle(.primary)
                    Spacer()
                    Picker(selection: $selectedQueueName) {
                        ForEach(queues) { q in
                            Text(q.queueName).tag(q.queueName)
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
            
        case "service":
            VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
                TextField("Target Worker Service Name", text: $serviceName)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                TextField("Environment (optional, default: production)", text: $serviceEnvironment)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            
        case "ai":
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(CloudnsColor.brandAccent)
                Text("Workers AI model execution binding.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
        default:
            EmptyView()
        }
    }
    
    // MARK: - Validation
    private var isValid: Bool {
        let cleanName = bindingName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return false }
        
        switch bindingType {
        case "kv_namespace": return !selectedKVId.isEmpty
        case "d1": return !selectedD1Id.isEmpty
        case "r2_bucket": return !selectedR2Bucket.isEmpty
        case "queue": return !selectedQueueName.isEmpty
        case "service": return !serviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case "ai": return true
        default: return false
        }
    }
    
    // MARK: - Helper Methods
    private func defaultBindingName(for type: String) -> String {
        switch type {
        case "kv_namespace": return "MY_KV"
        case "d1": return "DB"
        case "r2_bucket": return "BUCKET"
        case "queue": return "QUEUE"
        case "ai": return "AI"
        case "service": return "AUTH_SERVICE"
        default: return "RESOURCE"
        }
    }
    
    private func isDefaultBindingName(_ name: String) -> Bool {
        ["MY_KV", "DB", "BUCKET", "QUEUE", "AI", "AUTH_SERVICE", "RESOURCE"].contains(name)
    }
    
    private func loadAccountResources() async {
        isLoadingResources = true
        async let kvTask = try? KVService.shared.getKVNamespaces(accountId: accountId)
        async let d1Task = try? D1Service.shared.getD1Databases(accountId: accountId)
        async let r2Task = try? R2Service.shared.getR2Buckets(accountId: accountId)
        async let queueTask = try? QueueService.shared.getQueues(accountId: accountId)
        
        let (kvs, d1s, r2s, qs) = await (kvTask, d1Task, r2Task, queueTask)
        self.kvNamespaces = kvs ?? []
        self.d1Databases = d1s ?? []
        self.r2Buckets = r2s ?? []
        self.queues = qs ?? []
        
        if let firstKV = kvNamespaces.first { selectedKVId = firstKV.id }
        if let firstD1 = d1Databases.first { selectedD1Id = firstD1.uuid; selectedD1Name = firstD1.name }
        if let firstR2 = r2Buckets.first { selectedR2Bucket = firstR2.name }
        if let firstQueue = queues.first { selectedQueueName = firstQueue.queueName }
        
        isLoadingResources = false
    }
    
    private func saveBinding() async {
        isSaving = true
        errorMessage = nil
        HapticManager.impact(.medium)
        
        let cleanName = bindingName.trimmingCharacters(in: .whitespacesAndNewlines)
        let binding: WorkerBinding
        
        switch bindingType {
        case "kv_namespace":
            binding = WorkerBinding(name: cleanName, type: "kv_namespace", namespaceId: selectedKVId)
        case "d1":
            binding = WorkerBinding(name: cleanName, type: "d1", databaseId: selectedD1Id)
        case "r2_bucket":
            binding = WorkerBinding(name: cleanName, type: "r2_bucket", bucketName: selectedR2Bucket)
        case "queue":
            binding = WorkerBinding(name: cleanName, type: "queue", queueName: selectedQueueName)
        case "service":
            binding = WorkerBinding(
                name: cleanName,
                type: "service",
                service: serviceName.trimmingCharacters(in: .whitespacesAndNewlines),
                environment: serviceEnvironment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "production" : serviceEnvironment
            )
        case "ai":
            binding = WorkerBinding(name: cleanName, type: "ai")
        default:
            isSaving = false
            return
        }
        
        do {
            try await viewModel.saveResourceBinding(binding: binding)
            CloudnsToastManager.shared.showSuccess("Resource Bound", message: cleanName)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
