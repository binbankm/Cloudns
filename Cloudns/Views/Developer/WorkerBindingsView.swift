import SwiftUI

struct WorkerBindingsView: View {
    let accountId: String
    let scriptName: String
    let bindings: [WorkerBinding]
    
    @StateObject private var secretsViewModel: WorkerSecretsViewModel
    @State private var selectedTab: String = "resources" // "resources" | "variables" | "secrets"
    @State private var showingAddSheet = false
    @State private var variableToEdit: WorkerBinding?
    @State private var itemToDelete: (name: String, isSecret: Bool)?
    @State private var showingDeleteAlert = false
    
    init(accountId: String, scriptName: String, bindings: [WorkerBinding]) {
        self.accountId = accountId
        self.scriptName = scriptName
        self.bindings = bindings
        _secretsViewModel = StateObject(wrappedValue: WorkerSecretsViewModel(accountId: accountId, scriptName: scriptName))
    }
    
    private var resourceBindings: [WorkerBinding] {
        bindings.filter { $0.type != "secret_text" && $0.type != "plain_text" }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Category", selection: $selectedTab) {
                Text("Resources (\(resourceBindings.count))").tag("resources")
                Text("Variables (\(secretsViewModel.plainVariables.count))").tag("variables")
                Text("Secrets (\(secretsViewModel.secrets.count))").tag("secrets")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            
            contentList
                .centerConstrainedWidth(maxWidth: 840)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Bindings & Variables")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if selectedTab != "resources" {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Variable or Secret")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            WorkerAddVariableOrSecretSheetView(viewModel: secretsViewModel)
        }
        .sheet(item: $variableToEdit) { v in
            WorkerEditVariableSheetView(viewModel: secretsViewModel, variable: v)
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
        List {
            if selectedTab == "resources" {
                resourcesSection
            } else if selectedTab == "variables" {
                variablesSection
            } else {
                secretsSection
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - 1. Resources Section (KV, R2, D1, Queues, Services, etc.)
    @ViewBuilder
    private var resourcesSection: some View {
        Section(
            header: Text("Resource Bindings (\(resourceBindings.count))"),
            footer: Text("Cloudflare storage, queues, and services bound to this Worker environment.")
        ) {
            if resourceBindings.isEmpty {
                Text("No KV, R2, D1, Queue or Service bindings configured for this Worker.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(resourceBindings) { binding in
                    HStack(spacing: 12) {
                        Image(systemName: bindingIcon(for: binding.type))
                            .font(.body)
                            .foregroundStyle(bindingColor(for: binding.type))
                            .frame(width: 30, height: 30)
                            .background(bindingColor(for: binding.type).opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(binding.name)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                            
                            if let extra = binding.namespaceId ?? binding.bucketName ?? binding.databaseId ?? binding.service ?? binding.queueName {
                                Text(extra)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        CloudnsBadge(.custom(color: bindingColor(for: binding.type), text: binding.type.uppercased()), isCompact: true)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    // MARK: - 2. Variables Section
    @ViewBuilder
    private var variablesSection: some View {
        Section(
            header: Text(secretsViewModel.hasFetchedData ? "Plaintext Variables (\(secretsViewModel.plainVariables.count))" : "Plaintext Variables"),
            footer: Text("Plaintext environment variables are readable in worker script code.")
        ) {
            if !secretsViewModel.hasFetchedData {
                ForEach(0..<3, id: \.self) { idx in
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.body)
                            .foregroundStyle(.blue)
                            .frame(width: 30, height: 30)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("VARIABLE_\(idx + 1)")
                                .font(.body.monospaced().weight(.medium))
                            Text("environment_variable_value")
                                .font(.caption.monospaced())
                        }
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
                .skeletonLoading(true)
            } else if secretsViewModel.plainVariables.isEmpty {
                Text("No plaintext variables configured.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(secretsViewModel.plainVariables) { variable in
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.body)
                            .foregroundStyle(.blue)
                            .frame(width: 30, height: 30)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(variable.name)
                                .font(.body.monospaced().weight(.medium))
                                .foregroundStyle(.primary)
                            
                            if let text = variable.text, !text.isEmpty {
                                Text(text)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                        
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
    
    // MARK: - 3. Secrets Section
    @ViewBuilder
    private var secretsSection: some View {
        Section(
            header: Text(secretsViewModel.hasFetchedData ? "Encrypted Secrets (\(secretsViewModel.secrets.count))" : "Encrypted Secrets"),
            footer: Text("Secrets are encrypted at rest and masked in responses.")
        ) {
            if !secretsViewModel.hasFetchedData {
                ForEach(WorkerSecret.placeholders.prefix(3)) { secret in
                    HStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.body)
                            .foregroundStyle(.orange)
                            .frame(width: 30, height: 30)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(secret.name)
                                .font(.body.monospaced().weight(.medium))
                            Text("•••••••• (Encrypted Secret)")
                                .font(.caption.monospaced())
                        }
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
                .skeletonLoading(true)
            } else if secretsViewModel.secrets.isEmpty {
                Text("No encrypted secrets configured.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(secretsViewModel.secrets) { secret in
                    HStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.body)
                            .foregroundStyle(.orange)
                            .frame(width: 30, height: 30)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(secret.name)
                                .font(.body.monospaced().weight(.medium))
                                .foregroundStyle(.primary)
                            
                            Text("•••••••• (Encrypted Secret)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        CloudnsBadge(.proxied("SECRET"), isCompact: true)
                    }
                    .padding(.vertical, 2)
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
    
    private func bindingColor(for type: String) -> Color {
        switch type.lowercased() {
        case "kv_namespace": return .purple
        case "r2_bucket": return .blue
        case "d1": return .indigo
        case "queue": return .purple
        case "service": return .teal
        case "durable_object_namespace": return .cyan
        case "hyperdrive": return .green
        case "ai": return .orange
        default: return .orange
        }
    }
}
