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
        let resTitle = "Resources (\(resourceBindings.count))"
        let varsTitle = "Variables & Secrets (\(totalVariablesAndSecretsCount))"
        
        VStack(spacing: 0) {
            Picker("Category", selection: $selectedTab) {
                Text(resTitle).tag("resources")
                Text(varsTitle).tag("variables")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            .onChange(of: selectedTab) { _ in
                HIGFeedback.selection()
            }
            
            contentList
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Bindings & Variables")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if selectedTab == "resources" {
                        showingAttachResourceSheet = true
                    } else {
                        showingAddSheet = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(selectedTab == "resources" ? "Attach Resource" : "Add Variable or Secret")
            }
        }
        .sheet(isPresented: $showingAttachResourceSheet) {
            WorkerAttachResourceBindingSheetView(accountId: accountId, viewModel: secretsViewModel)
        }
        .sheet(isPresented: $showingAddSheet) {
            WorkerAddVariableOrSecretSheetView(viewModel: secretsViewModel)
        }
        .sheet(item: $variableToEdit) { v in
            WorkerEditVariableSheetView(viewModel: secretsViewModel, variable: v)
        }
        .confirmationDialog("Unbind Resource", isPresented: $showingUnbindAlert, titleVisibility: .visible, presenting: bindingToDelete) { binding in
            Button("Unbind '\(binding.name)'", role: .destructive) {
                Task {
                    do {
                        try await secretsViewModel.deleteResourceBinding(name: binding.name)
                        HIGFeedback.success()
                    } catch {
                        HIGFeedback.error()
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
                        HIGFeedback.success()
                    } catch {
                        HIGFeedback.error()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text("Are you sure you want to delete \(item.isSecret ? "secret" : "environment variable") '\(item.name)'?")
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
            if selectedTab == "resources" {
                resourcesSection
            } else {
                variablesSection
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if secretsViewModel.hasFetchedData {
                if selectedTab == "resources" && resourceBindings.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Resource Bindings",
                            systemImage: "link.badge.plus",
                            description: "Bind Cloudflare KV, D1, R2, Queues, or AI directly to this Worker.",
                            actionTitle: "Attach Resource",
                            action: { showingAttachResourceSheet = true }
                        )
                    )
                } else if selectedTab == "variables" && totalVariablesAndSecretsCount == 0 {
                    HIGContentState(
                        .empty(
                            title: "No Variables or Secrets",
                            systemImage: "slider.horizontal.3",
                            description: "Configure plaintext environment variables and encrypted secrets.",
                            actionTitle: "Add Variable",
                            action: { showingAddSheet = true }
                        )
                    )
                }
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
            Image(systemName: bindingIcon(for: binding.type))
                .font(.title3)
                .foregroundStyle(bindingColor(for: binding.type))
                .frame(width: 32, height: 32)
                .background(bindingColor(for: binding.type).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
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
                            Text(label).tag(value)
                        }
                    }
                }
                
                Section(header: Text("Configuration")) {
                    TextField("Binding Name (e.g. MY_KV)", text: $bindingName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    
                    if bindingType != "ai" {
                        TextField(targetPlaceholder, text: $targetIdentifier)
                            .keyboardType(.asciiCapable)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
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
}
