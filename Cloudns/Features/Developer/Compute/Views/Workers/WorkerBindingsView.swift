import SwiftUI

// MARK: - WorkerBindingsView

struct WorkerBindingsView: View {
    // MARK: - Properties
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
    
    // MARK: - Lifecycle / Init
    init(accountId: String, scriptName: String, bindings: [WorkerBinding]) {
        self.accountId = accountId
        self.scriptName = scriptName
        self.bindings = bindings
        _secretsViewModel = StateObject(
            wrappedValue: WorkerSecretsViewModel(accountId: accountId, scriptName: scriptName)
        )
    }
    
    // MARK: - Computed Properties
    private var resourceBindings: [WorkerBinding] {
        if secretsViewModel.hasFetchedData {
            return secretsViewModel.resourceBindings
        }
        return bindings.filter { $0.type != "secret_text" && $0.type != "plain_text" }
    }
    
    private var totalVariablesAndSecretsCount: Int {
        secretsViewModel.plainVariables.count + secretsViewModel.secrets.count
    }
    
    private var kvBindings: [WorkerBinding] { resourceBindings.filter { $0.type == "kv_namespace" } }
    private var d1Bindings: [WorkerBinding] { resourceBindings.filter { $0.type == "d1" } }
    private var r2Bindings: [WorkerBinding] { resourceBindings.filter { $0.type == "r2_bucket" } }
    private var queueBindings: [WorkerBinding] { resourceBindings.filter { $0.type == "queue" } }
    private var aiBindings: [WorkerBinding] { resourceBindings.filter { $0.type == "ai" } }
    private var otherBindings: [WorkerBinding] {
        resourceBindings.filter { !["kv_namespace", "d1", "r2_bucket", "queue", "ai"].contains($0.type) }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            tabSelector
            
            contentList
                .centerConstrainedWidth(maxWidth: 840)
        }
        .background(CloudnsColor.groupedBackground)
        .navigationTitle("Bindings & Variables")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                addButton
            }
        }
        .sheet(isPresented: $showingAttachResourceSheet) {
            WorkerAttachResourceBindingSheetView(accountId: accountId, viewModel: secretsViewModel)
        }
        .sheet(isPresented: $showingAddSheet) {
            WorkerAddVariableOrSecretSheetView(viewModel: secretsViewModel)
        }
        .sheet(item: $variableToEdit) { variable in
            WorkerEditVariableSheetView(viewModel: secretsViewModel, variable: variable)
        }
        .confirmationDialog(
            "Unbind Resource",
            isPresented: $showingUnbindAlert,
            titleVisibility: .visible,
            presenting: bindingToDelete
        ) { binding in
            Button("Unbind '\(binding.name)'", role: .destructive) {
                unbindResource(binding)
            }
            Button("Cancel", role: .cancel) {}
        } message: { binding in
            Text("Are you sure you want to unbind resource '\(binding.name)' from Worker '\(scriptName)'?")
        }
        .confirmationDialog(
            "Delete Item",
            isPresented: $showingDeleteAlert,
            titleVisibility: .visible,
            presenting: itemToDelete
        ) { item in
            Button("Delete '\(item.name)'", role: .destructive) {
                deleteItem(item)
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
    
    // MARK: - Private Views
    private var tabSelector: some View {
        Picker("Category", selection: $selectedTab) {
            Text("Resources (\(resourceBindings.count))").tag("resources")
            Text("Variables & Secrets (\(totalVariablesAndSecretsCount))").tag("variables")
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(CloudnsColor.groupedBackground)
        .onChange(of: selectedTab) { _ in
            HapticManager.impact(.light)
        }
    }
    
    private var addButton: some View {
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
    
    @ViewBuilder
    private var contentList: some View {
        if selectedTab == "resources" && resourceBindings.isEmpty && secretsViewModel.hasFetchedData {
            emptyResourcesView
        } else if selectedTab == "variables" && secretsViewModel.plainVariables.isEmpty && secretsViewModel.secrets.isEmpty && secretsViewModel.hasFetchedData {
            emptyVariablesView
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
    
    private var emptyResourcesView: some View {
        ScrollView {
            CloudnsEmptyStateView(
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
    }
    
    private var emptyVariablesView: some View {
        ScrollView {
            CloudnsEmptyStateView(
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
    }
    
    @ViewBuilder
    private var resourcesSection: some View {
        if !kvBindings.isEmpty {
            Section(header: Text("KV Namespaces (\(kvBindings.count))")) {
                ForEach(kvBindings) { binding in
                    WorkerResourceRowView(binding: binding) {
                        bindingToDelete = binding
                        showingUnbindAlert = true
                    }
                }
            }
        }
        
        if !d1Bindings.isEmpty {
            Section(header: Text("D1 Databases (\(d1Bindings.count))")) {
                ForEach(d1Bindings) { binding in
                    WorkerResourceRowView(binding: binding) {
                        bindingToDelete = binding
                        showingUnbindAlert = true
                    }
                }
            }
        }
        
        if !r2Bindings.isEmpty {
            Section(header: Text("R2 Buckets (\(r2Bindings.count))")) {
                ForEach(r2Bindings) { binding in
                    WorkerResourceRowView(binding: binding) {
                        bindingToDelete = binding
                        showingUnbindAlert = true
                    }
                }
            }
        }
        
        if !queueBindings.isEmpty {
            Section(header: Text("Message Queues (\(queueBindings.count))")) {
                ForEach(queueBindings) { binding in
                    WorkerResourceRowView(binding: binding) {
                        bindingToDelete = binding
                        showingUnbindAlert = true
                    }
                }
            }
        }
        
        if !aiBindings.isEmpty {
            Section(header: Text("Workers AI (\(aiBindings.count))")) {
                ForEach(aiBindings) { binding in
                    WorkerResourceRowView(binding: binding) {
                        bindingToDelete = binding
                        showingUnbindAlert = true
                    }
                }
            }
        }
        
        if !otherBindings.isEmpty {
            Section(header: Text("Services & Other Bindings (\(otherBindings.count))")) {
                ForEach(otherBindings) { binding in
                    WorkerResourceRowView(binding: binding) {
                        bindingToDelete = binding
                        showingUnbindAlert = true
                    }
                }
            }
        }
    }
    
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
                    .skeletonLoading(true)
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
                    WorkerVariableRowView(
                        variable: variable,
                        onEdit: {
                            variableToEdit = variable
                        },
                        onDelete: {
                            itemToDelete = (name: variable.name, isSecret: false)
                            showingDeleteAlert = true
                        }
                    )
                }
            }
        }
    }
    
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
                    .skeletonLoading(true)
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
                    WorkerSecretRowView(
                        secret: secret,
                        onDelete: {
                            itemToDelete = (name: secret.name, isSecret: true)
                            showingDeleteAlert = true
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Actions
    private func unbindResource(_ binding: WorkerBinding) {
        Task {
            do {
                try await secretsViewModel.deleteResourceBinding(name: binding.name)
                CloudnsToastManager.shared.showSuccess("Resource Unbound", message: binding.name)
            } catch {
                CloudnsToastManager.shared.showError("Unbind Failed", message: error.localizedDescription)
            }
        }
    }
    
    private func deleteItem(_ item: (name: String, isSecret: Bool)) {
        Task {
            do {
                if item.isSecret {
                    try await secretsViewModel.deleteSecret(name: item.name)
                } else {
                    try await secretsViewModel.deletePlainVariable(name: item.name)
                }
                CloudnsToastManager.shared.showSuccess("Deleted", message: item.name)
            } catch {
                CloudnsToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
            }
        }
    }
}
