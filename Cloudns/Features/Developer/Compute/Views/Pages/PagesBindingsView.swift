import SwiftUI

// MARK: - EditVarWrapper Helper

private struct EditVarWrapper: Identifiable {
    var id: String { name }
    let name: String
    let value: PagesEnvVarValue
}

// MARK: - PagesBindingsView

struct PagesBindingsView: View {
    // MARK: - Properties
    let accountId: String
    let project: PagesProject
    @State private var selectedEnv = "production" // "production" | "preview"
    
    // Environment Variables State
    @State private var productionEnvVars: [String: PagesEnvVarValue] = [:]
    @State private var previewEnvVars: [String: PagesEnvVarValue] = [:]
    
    // Resource Bindings State
    @State private var productionKV: [String: PagesKVBinding] = [:]
    @State private var previewKV: [String: PagesKVBinding] = [:]
    
    @State private var productionD1: [String: PagesD1Binding] = [:]
    @State private var previewD1: [String: PagesD1Binding] = [:]
    
    @State private var productionR2: [String: PagesR2Binding] = [:]
    @State private var previewR2: [String: PagesR2Binding] = [:]
    
    @State private var productionAI: [String: PagesAIBinding] = [:]
    @State private var previewAI: [String: PagesAIBinding] = [:]
    
    // Sheet & Alert States
    @State private var showingAddVariableSheet = false
    @State private var showingAttachResourceSheet = false
    @State private var variableToEdit: (name: String, value: PagesEnvVarValue)?
    @State private var varNameToDelete: String?
    @State private var resourceToUnbind: (name: String, type: String)?
    @State private var showingDeleteAlert = false
    @State private var showingUnbindAlert = false
    @State private var isDeleting = false
    
    // MARK: - Lifecycle / Init
    init(accountId: String, project: PagesProject) {
        self.accountId = accountId
        self.project = project
        _productionEnvVars = State(initialValue: project.deploymentConfigs?.production?.envVars ?? [:])
        _previewEnvVars = State(initialValue: project.deploymentConfigs?.preview?.envVars ?? [:])
        
        _productionKV = State(initialValue: project.deploymentConfigs?.production?.kvNamespaces ?? [:])
        _previewKV = State(initialValue: project.deploymentConfigs?.preview?.kvNamespaces ?? [:])
        
        _productionD1 = State(initialValue: project.deploymentConfigs?.production?.d1Databases ?? [:])
        _previewD1 = State(initialValue: project.deploymentConfigs?.preview?.d1Databases ?? [:])
        
        _productionR2 = State(initialValue: project.deploymentConfigs?.production?.r2Buckets ?? [:])
        _previewR2 = State(initialValue: project.deploymentConfigs?.preview?.r2Buckets ?? [:])
        
        _productionAI = State(initialValue: project.deploymentConfigs?.production?.aiBindings ?? [:])
        _previewAI = State(initialValue: project.deploymentConfigs?.preview?.aiBindings ?? [:])
    }
    
    // MARK: - Computed Properties
    private var currentEnvVars: [String: PagesEnvVarValue] {
        selectedEnv == "production" ? productionEnvVars : previewEnvVars
    }
    
    private var plainVariables: [String: PagesEnvVarValue] {
        currentEnvVars.filter { !$0.value.isSecret }
    }
    
    private var secretVariables: [String: PagesEnvVarValue] {
        currentEnvVars.filter { $0.value.isSecret }
    }
    
    private var currentKV: [String: PagesKVBinding] {
        selectedEnv == "production" ? productionKV : previewKV
    }
    
    private var currentD1: [String: PagesD1Binding] {
        selectedEnv == "production" ? productionD1 : previewD1
    }
    
    private var currentR2: [String: PagesR2Binding] {
        selectedEnv == "production" ? productionR2 : previewR2
    }
    
    private var currentAI: [String: PagesAIBinding] {
        selectedEnv == "production" ? productionAI : previewAI
    }
    
    private var currentConfig: PagesEnvConfig? {
        selectedEnv == "production" ? project.deploymentConfigs?.production : project.deploymentConfigs?.preview
    }
    
    private var productionTotalCount: Int {
        productionEnvVars.count + productionKV.count + productionD1.count + productionR2.count + productionAI.count
    }
    
    private var previewTotalCount: Int {
        previewEnvVars.count + previewKV.count + previewD1.count + previewR2.count + previewAI.count
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            environmentPicker
            
            contentList
                .centerConstrainedWidth(maxWidth: 840)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Bindings & Variables")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                addMenu
            }
        }
        .sheet(isPresented: $showingAddVariableSheet) {
            addVariableSheet
        }
        .sheet(isPresented: $showingAttachResourceSheet) {
            attachResourceSheet
        }
        .sheet(item: Binding(
            get: { variableToEdit.map { EditVarWrapper(name: $0.name, value: $0.value) } },
            set: { variableToEdit = $0.map { ($0.name, $0.value) } }
        )) { wrapper in
            editVariableSheet(for: wrapper)
        }
        .confirmationDialog(
            "Delete Variable",
            isPresented: $showingDeleteAlert,
            titleVisibility: .visible,
            presenting: varNameToDelete
        ) { varName in
            Button("Delete '\(varName)'", role: .destructive) {
                Task { await deleteVariable(name: varName) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { varName in
            Text("Are you sure you want to delete environment variable '\(varName)' from \(selectedEnv.capitalized)?")
        }
        .confirmationDialog(
            "Unbind Resource",
            isPresented: $showingUnbindAlert,
            titleVisibility: .visible,
            presenting: resourceToUnbind
        ) { res in
            Button("Unbind '\(res.name)'", role: .destructive) {
                Task { await unbindResource(name: res.name, type: res.type) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { res in
            Text("Are you sure you want to unbind \(res.type.uppercased()) resource '\(res.name)' from \(selectedEnv.capitalized)?")
        }
    }
    
    // MARK: - Private Views
    private var environmentPicker: some View {
        Picker("Environment", selection: $selectedEnv) {
            Text("Production (\(productionTotalCount))").tag("production")
            Text("Preview (\(previewTotalCount))").tag("preview")
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
        .onChange(of: selectedEnv) { _ in
            HapticManager.impact(.light)
        }
    }
    
    private var addMenu: some View {
        Menu {
            Button {
                showingAddVariableSheet = true
            } label: {
                Label("Add Environment Variable", systemImage: "slider.horizontal.3")
            }
            
            Button {
                showingAttachResourceSheet = true
            } label: {
                Label("Attach Resource (KV / D1 / R2 / AI)", systemImage: "link.badge.plus")
            }
        } label: {
            Image(systemName: "plus")
        }
        .accessibilityLabel("Add Variable or Resource")
    }
    
    private var contentList: some View {
        List {
            variablesSection
            secretsSection
            kvSection
            d1Section
            r2Section
            aiSection
            compatibilitySection
        }
        .listStyle(.insetGrouped)
    }
    
    private var variablesSection: some View {
        Section(
            header: Text("Plaintext Variables (\(plainVariables.count))"),
            footer: Text("Plaintext variables are accessible in Pages Functions via context.env.VAR_NAME.")
        ) {
            if plainVariables.isEmpty {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.secondary)
                    Text("No plaintext variables configured for \(selectedEnv.capitalized).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            } else {
                ForEach(Array(plainVariables.keys.sorted()), id: \.self) { key in
                    if let item = plainVariables[key] {
                        PagesEnvVarRowView(
                            name: key,
                            value: item,
                            onEdit: {
                                variableToEdit = (name: key, value: item)
                            },
                            onDelete: {
                                varNameToDelete = key
                                showingDeleteAlert = true
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var secretsSection: some View {
        Section(
            header: Text("Encrypted Secrets (\(secretVariables.count))"),
            footer: Text("Secrets are encrypted at rest and never exposed in cleartext.")
        ) {
            if secretVariables.isEmpty {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundStyle(.secondary)
                    Text("No encrypted secrets configured for \(selectedEnv.capitalized).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            } else {
                ForEach(Array(secretVariables.keys.sorted()), id: \.self) { key in
                    if let item = secretVariables[key] {
                        PagesEnvVarRowView(
                            name: key,
                            value: item,
                            onEdit: {},
                            onDelete: {
                                varNameToDelete = key
                                showingDeleteAlert = true
                            }
                        )
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var kvSection: some View {
        if !currentKV.isEmpty {
            Section(header: Text("KV Namespaces (\(currentKV.count))")) {
                ForEach(Array(currentKV.keys.sorted()), id: \.self) { key in
                    PagesResourceRowView(
                        name: key,
                        targetId: currentKV[key]?.namespaceId,
                        type: "kv"
                    ) {
                        resourceToUnbind = (name: key, type: "kv")
                        showingUnbindAlert = true
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var d1Section: some View {
        if !currentD1.isEmpty {
            Section(header: Text("D1 Databases (\(currentD1.count))")) {
                ForEach(Array(currentD1.keys.sorted()), id: \.self) { key in
                    PagesResourceRowView(
                        name: key,
                        targetId: currentD1[key]?.id,
                        type: "d1"
                    ) {
                        resourceToUnbind = (name: key, type: "d1")
                        showingUnbindAlert = true
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var r2Section: some View {
        if !currentR2.isEmpty {
            Section(header: Text("R2 Buckets (\(currentR2.count))")) {
                ForEach(Array(currentR2.keys.sorted()), id: \.self) { key in
                    PagesResourceRowView(
                        name: key,
                        targetId: currentR2[key]?.name,
                        type: "r2"
                    ) {
                        resourceToUnbind = (name: key, type: "r2")
                        showingUnbindAlert = true
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var aiSection: some View {
        if !currentAI.isEmpty {
            Section(header: Text("Workers AI (\(currentAI.count))")) {
                ForEach(Array(currentAI.keys.sorted()), id: \.self) { key in
                    PagesResourceRowView(
                        name: key,
                        targetId: nil,
                        type: "ai"
                    ) {
                        resourceToUnbind = (name: key, type: "ai")
                        showingUnbindAlert = true
                    }
                }
            }
        }
    }
    
    private var compatibilitySection: some View {
        Section(header: Text("Compatibility Settings")) {
            HStack {
                Text("Compatibility Date")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(currentConfig?.compatibilityDate ?? "Default")
                    .font(.body.monospacedDigit())
            }
            
            if let flags = currentConfig?.compatibilityFlags, !flags.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Compatibility Flags")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(flags.joined(separator: ", "))
                        .font(.caption.monospaced())
                        .foregroundStyle(.primary)
                }
            }
        }
    }
    
    private var addVariableSheet: some View {
        PagesAddVariableSheetView(
            accountId: accountId,
            projectName: project.name,
            environment: selectedEnv,
            existingEnvVars: currentEnvVars
        ) { updated in
            if selectedEnv == "production" {
                productionEnvVars = updated
            } else {
                previewEnvVars = updated
            }
        }
    }
    
    private var attachResourceSheet: some View {
        PagesAttachResourceBindingSheetView(
            accountId: accountId,
            projectName: project.name,
            environment: selectedEnv,
            existingKV: currentKV,
            existingD1: currentD1,
            existingR2: currentR2,
            existingAI: currentAI
        ) { env, kv, d1, r2, ai in
            if env == "production" {
                productionKV = kv
                productionD1 = d1
                productionR2 = r2
                productionAI = ai
            } else {
                previewKV = kv
                previewD1 = d1
                previewR2 = r2
                previewAI = ai
            }
        }
    }
    
    private func editVariableSheet(for wrapper: EditVarWrapper) -> some View {
        PagesAddVariableSheetView(
            accountId: accountId,
            projectName: project.name,
            environment: selectedEnv,
            existingEnvVars: currentEnvVars,
            initialName: wrapper.name,
            initialValue: wrapper.value.value ?? "",
            initialIsSecret: wrapper.value.isSecret
        ) { updated in
            if selectedEnv == "production" {
                productionEnvVars = updated
            } else {
                previewEnvVars = updated
            }
        }
    }
    
    // MARK: - Actions
    private func deleteVariable(name: String) async {
        isDeleting = true
        var updated = currentEnvVars
        updated.removeValue(forKey: name)
        
        withAnimation {
            if selectedEnv == "production" {
                productionEnvVars = updated
            } else {
                previewEnvVars = updated
            }
        }
        
        do {
            try await PagesService.shared.updatePagesEnvVars(
                accountId: accountId,
                projectName: project.name,
                environment: selectedEnv,
                envVars: updated
            )
            CloudnsToastManager.shared.showSuccess("Variable Deleted", message: name)
            HapticManager.notification(.success)
        } catch {
            CloudnsToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
        isDeleting = false
    }
    
    private func unbindResource(name: String, type: String) async {
        isDeleting = true
        var updatedKV = currentKV
        var updatedD1 = currentD1
        var updatedR2 = currentR2
        var updatedAI = currentAI
        
        switch type {
        case "kv": updatedKV.removeValue(forKey: name)
        case "d1": updatedD1.removeValue(forKey: name)
        case "r2": updatedR2.removeValue(forKey: name)
        case "ai": updatedAI.removeValue(forKey: name)
        default: break
        }
        
        withAnimation {
            if selectedEnv == "production" {
                productionKV = updatedKV
                productionD1 = updatedD1
                productionR2 = updatedR2
                productionAI = updatedAI
            } else {
                previewKV = updatedKV
                previewD1 = updatedD1
                previewR2 = updatedR2
                previewAI = updatedAI
            }
        }
        
        do {
            try await PagesService.shared.updatePagesResourceBindings(
                accountId: accountId,
                projectName: project.name,
                environment: selectedEnv,
                kvNamespaces: updatedKV,
                d1Databases: updatedD1,
                r2Buckets: updatedR2,
                aiBindings: updatedAI
            )
            CloudnsToastManager.shared.showSuccess("Resource Unbound", message: name)
            HapticManager.notification(.success)
        } catch {
            CloudnsToastManager.shared.showError("Unbind Failed", message: error.localizedDescription)
        }
        isDeleting = false
    }
}
