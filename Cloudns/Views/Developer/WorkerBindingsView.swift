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
        VStack(spacing: 0) {
            Picker("Category", selection: $selectedTab) {
                Text("Resources (\(resourceBindings.count))").tag("resources")
                Text("Variables & Secrets (\(totalVariablesAndSecretsCount))").tag("variables")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            .onChange(of: selectedTab) { _ in
                HapticManager.impact(.light)
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
                        ToastManager.shared.showSuccess("Resource Unbound", message: binding.name)
                    } catch {
                        ToastManager.shared.showError("Unbind Failed", message: error.localizedDescription)
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
                        ToastManager.shared.showSuccess("Deleted", message: item.name)
                    } catch {
                        ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
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
        if selectedTab == "resources" && resourceBindings.isEmpty && secretsViewModel.hasFetchedData {
            ScrollView {
                EmptyStateView(
                    icon: "shippingbox.fill",
                    title: "No Resource Bindings",
                    message: "Bind KV namespaces, D1 SQL databases, R2 buckets, and Queues directly to this Worker.",
                    iconColor: .orange,
                    actionTitle: "Bind First Resource",
                    action: {
                        HapticManager.impact(.light)
                        showingAttachResourceSheet = true
                    }
                )
                .padding(.top, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if selectedTab == "variables" && secretsViewModel.plainVariables.isEmpty && secretsViewModel.secrets.isEmpty && secretsViewModel.hasFetchedData {
            ScrollView {
                EmptyStateView(
                    icon: "slider.horizontal.3",
                    title: "No Environment Variables",
                    message: "Configure plaintext variables and encrypted secrets accessible in your Worker code.",
                    iconColor: .orange,
                    actionTitle: "Add Variable or Secret",
                    action: {
                        HapticManager.impact(.light)
                        showingAddSheet = true
                    }
                )
                .padding(.top, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                if selectedTab == "resources" {
                    resourcesSection
                } else {
                    variablesSection
                    secretsSection
                }
            }
            .listStyle(.insetGrouped)
        }
    }
    
    // MARK: - Resources Section (Categorized)
    @ViewBuilder
    private var resourcesSection: some View {
            // KV Namespaces
            if !kvBindings.isEmpty {
                Section(header: Text("KV Namespaces (\(kvBindings.count))")) {
                    ForEach(kvBindings) { binding in
                        resourceRow(binding)
                    }
                }
            }
            
            // D1 Databases
            if !d1Bindings.isEmpty {
                Section(header: Text("D1 Databases (\(d1Bindings.count))")) {
                    ForEach(d1Bindings) { binding in
                        resourceRow(binding)
                    }
                }
            }
            
            // R2 Buckets
            if !r2Bindings.isEmpty {
                Section(header: Text("R2 Buckets (\(r2Bindings.count))")) {
                    ForEach(r2Bindings) { binding in
                        resourceRow(binding)
                    }
                }
            }
            
            // Queues
            if !queueBindings.isEmpty {
                Section(header: Text("Message Queues (\(queueBindings.count))")) {
                    ForEach(queueBindings) { binding in
                        resourceRow(binding)
                    }
                }
            }
            
            // AI Bindings
            if !aiBindings.isEmpty {
                Section(header: Text("Workers AI (\(aiBindings.count))")) {
                    ForEach(aiBindings) { binding in
                        resourceRow(binding)
                    }
                }
            }
            
            // Other Services / Hyperdrive
            if !otherBindings.isEmpty {
                Section(header: Text("Services & Other Bindings (\(otherBindings.count))")) {
                    ForEach(otherBindings) { binding in
                        resourceRow(binding)
                    }
                }
            }
    }
    
    @ViewBuilder
    private func resourceRow(_ binding: WorkerBinding) -> some View {
        HStack(spacing: 12) {
            Image(systemName: bindingIcon(for: binding.type))
                .font(.body)
                .foregroundStyle(bindingColor(for: binding.type))
                .frame(width: 32, height: 32)
                .background(bindingColor(for: binding.type).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(binding.name)
                    .font(.body.monospaced().weight(.semibold))
                    .foregroundStyle(.primary)
                
                if let extra = binding.namespaceId ?? binding.bucketName ?? binding.databaseId ?? binding.service ?? binding.queueName {
                    Text(extra)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Spacer()
            
            CloudnsBadge(.custom(color: bindingColor(for: binding.type), text: bindingBadgeTitle(for: binding.type)), isCompact: true)
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                UIPasteboard.general.string = binding.name
                HapticManager.notification(.success)
                ToastManager.shared.showCopied("Binding variable copied")
            } label: {
                Label("Copy Variable Name", systemImage: "doc.on.doc")
            }
            
            if let extra = binding.namespaceId ?? binding.bucketName ?? binding.databaseId {
                Button {
                    UIPasteboard.general.string = extra
                    HapticManager.notification(.success)
                    ToastManager.shared.showCopied("Target ID copied")
                } label: {
                    Label("Copy Target Resource ID", systemImage: "number")
                }
            }
            
            Button(role: .destructive) {
                bindingToDelete = binding
                showingUnbindAlert = true
            } label: {
                Label("Unbind Resource", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                bindingToDelete = binding
                showingUnbindAlert = true
            } label: {
                Label("Unbind", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Variables Section (Plaintext)
    @ViewBuilder
    private var variablesSection: some View {
        Section(
            header: Text("Plaintext Variables (\(secretsViewModel.plainVariables.count))"),
            footer: Text("Plaintext environment variables are readable in script code via env.VAR_NAME.")
        ) {
            if !secretsViewModel.hasFetchedData {
                ForEach(0..<2, id: \.self) { idx in
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .frame(width: 32, height: 32)
                        VStack(alignment: .leading) {
                            Text("VARIABLE_\(idx + 1)")
                            Text("value")
                        }
                    }
                    .redacted(reason: .placeholder)
                }
            } else if secretsViewModel.plainVariables.isEmpty {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.secondary)
                    Text("No plaintext variables configured.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            } else {
                ForEach(secretsViewModel.plainVariables) { variable in
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.body)
                            .foregroundStyle(.blue)
                            .frame(width: 32, height: 32)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(variable.name)
                                .font(.body.monospaced().weight(.semibold))
                                .foregroundStyle(.primary)
                            
                            if let text = variable.text, !text.isEmpty {
                                Text(text)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                        
                        CloudnsBadge(.custom(color: .blue, text: "VARIABLE"), isCompact: true)
                        
                        Button {
                            variableToEdit = variable
                        } label: {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .contextMenu {
                        if let val = variable.text {
                            Button {
                                UIPasteboard.general.string = val
                                HapticManager.notification(.success)
                                ToastManager.shared.showCopied("Value copied")
                            } label: {
                                Label("Copy Value", systemImage: "doc.on.doc")
                            }
                        }
                        Button {
                            UIPasteboard.general.string = variable.name
                            HapticManager.notification(.success)
                            ToastManager.shared.showCopied("Key copied")
                        } label: {
                            Label("Copy Variable Name", systemImage: "doc.on.doc")
                        }
                        Button {
                            variableToEdit = variable
                        } label: {
                            Label("Edit Variable", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            itemToDelete = (name: variable.name, isSecret: false)
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Variable", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            itemToDelete = (name: variable.name, isSecret: false)
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Secrets Section (Encrypted)
    @ViewBuilder
    private var secretsSection: some View {
        Section(
            header: Text("Encrypted Secrets (\(secretsViewModel.secrets.count))"),
            footer: Text("Secrets are encrypted at rest and masked in responses.")
        ) {
            if !secretsViewModel.hasFetchedData {
                ForEach(WorkerSecret.placeholders.prefix(2)) { secret in
                    HStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .frame(width: 32, height: 32)
                        VStack(alignment: .leading) {
                            Text(secret.name)
                            Text("••••••••")
                        }
                    }
                    .redacted(reason: .placeholder)
                }
            } else if secretsViewModel.secrets.isEmpty {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundStyle(.secondary)
                    Text("No encrypted secrets configured.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            } else {
                ForEach(secretsViewModel.secrets) { secret in
                    HStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.body)
                            .foregroundStyle(.orange)
                            .frame(width: 32, height: 32)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(secret.name)
                                .font(.body.monospaced().weight(.semibold))
                                .foregroundStyle(.primary)
                            
                            Text("•••••••••••• (Encrypted)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        CloudnsBadge(.proxied("SECRET"), isCompact: true)
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = secret.name
                            HapticManager.notification(.success)
                            ToastManager.shared.showCopied("Secret name copied")
                        } label: {
                            Label("Copy Secret Name", systemImage: "doc.on.doc")
                        }
                        Button(role: .destructive) {
                            itemToDelete = (name: secret.name, isSecret: true)
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Secret", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            itemToDelete = (name: secret.name, isSecret: true)
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
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
        case "queue": return "QUEUE"
        case "service": return "SERVICE"
        case "ai": return "AI"
        case "hyperdrive": return "HYPERDRIVE"
        default: return type.uppercased()
        }
    }
    
    private func bindingColor(for type: String) -> Color {
        switch type.lowercased() {
        case "kv_namespace": return .purple
        case "r2_bucket": return .blue
        case "d1": return .indigo
        case "queue": return .purple
        case "service": return .teal
        case "durable_object_namespace": return .cyan
        case "hyperdrive": return .green
        case "ai": return .pink
        default: return .orange
        }
    }
}
