import SwiftUI

// MARK: - Professional PagesBindingsView

struct PagesBindingsView: View {
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
    
    private var currentStorageResourcesCount: Int {
        currentKV.count + currentD1.count + currentR2.count + currentAI.count
    }
    
    private var totalBindingsCount: Int {
        currentEnvVars.count + currentStorageResourcesCount
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
    
    var body: some View {
        let prodLabel = "Production (\(productionTotalCount))"
        let prevLabel = "Preview (\(previewTotalCount))"
        
        VStack(spacing: 0) {
            // Environment Segmented Switcher
            Picker("Environment", selection: $selectedEnv) {
                Text(prodLabel).tag("production")
                Text(prevLabel).tag("preview")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            .onChange(of: selectedEnv) { _ in
                HIGFeedback.impact(.light)
            }
            
            contentList
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Bindings & Variables")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
        }
        .sheet(isPresented: $showingAddVariableSheet) {
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
        .sheet(isPresented: $showingAttachResourceSheet) {
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
        .sheet(item: Binding(
            get: { variableToEdit.map { EditVarWrapper(name: $0.name, value: $0.value) } },
            set: { variableToEdit = $0.map { ($0.name, $0.value) } }
        )) { wrapper in
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
        .confirmationDialog("Delete Variable", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: varNameToDelete) { varName in
            Button("Delete '\(varName)'", role: .destructive) {
                Task { await deleteVariable(name: varName) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { varName in
            Text("Are you sure you want to delete environment variable '\(varName)' from \(selectedEnv.capitalized)?")
        }
        .confirmationDialog("Unbind Resource", isPresented: $showingUnbindAlert, titleVisibility: .visible, presenting: resourceToUnbind) { res in
            Button("Unbind '\(res.name)'", role: .destructive) {
                Task { await unbindResource(name: res.name, type: res.type) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { res in
            Text("Are you sure you want to unbind \(res.type.uppercased()) resource '\(res.name)' from \(selectedEnv.capitalized)?")
        }
    }
    
    @ViewBuilder
    private var contentList: some View {
        List {
            // MARK: - 1. Plaintext Variables
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
                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.body)
                                    .foregroundStyle(.blue)
                                    .frame(width: 32, height: 32)
                                    .background(Color.blue.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .accessibilityHidden(true)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(key)
                                        .font(.body.monospaced().weight(.semibold))
                                        .foregroundStyle(.primary)
                                    
                                    if let val = item.value, !val.isEmpty {
                                        Text(val)
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                
                                Spacer()
                                
                                HIGBadge(.custom(color: .blue, text: "VARIABLE"), isCompact: true)
                                
                                Button {
                                    variableToEdit = (name: key, value: item)
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
                                if let val = item.value {
                                    Button {
                                        UIPasteboard.general.string = val
                                        HIGFeedback.success()
                                        HIGFeedback.impact(.light)
                                    } label: {
                                        Label("Copy Value", systemImage: "doc.on.doc")
                                    }
                                }
                                Button {
                                    UIPasteboard.general.string = key
                                    HIGFeedback.success()
                                    HIGFeedback.impact(.light)
                                } label: {
                                    Label("Copy Key Name", systemImage: "doc.on.doc")
                                }
                                Button {
                                    variableToEdit = (name: key, value: item)
                                } label: {
                                    Label("Edit Variable", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    varNameToDelete = key
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete Variable", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    varNameToDelete = key
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            
            // MARK: - 2. Encrypted Secrets
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
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "key.fill")
                                .font(.body)
                                .foregroundStyle(.orange)
                                .frame(width: 32, height: 32)
                                .background(Color.orange.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .accessibilityHidden(true)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(key)
                                    .font(.body.monospaced().weight(.semibold))
                                    .foregroundStyle(.primary)
                                
                                Text("•••••••••••• (Encrypted Secret)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            HIGBadge(.proxied("SECRET"), isCompact: true)
                        }
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = key
                                HIGFeedback.success()
                                HIGFeedback.impact(.light)
                            } label: {
                                Label("Copy Secret Name", systemImage: "doc.on.doc")
                            }
                            Button(role: .destructive) {
                                varNameToDelete = key
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Secret", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                varNameToDelete = key
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            // MARK: - 3. KV Namespaces
            if !currentKV.isEmpty {
                Section(header: Text("KV Namespaces (\(currentKV.count))")) {
                    ForEach(Array(currentKV.keys.sorted()), id: \.self) { key in
                        HStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .font(.body)
                                .foregroundStyle(.purple)
                                .frame(width: 32, height: 32)
                                .background(Color.purple.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .accessibilityHidden(true)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(key)
                                    .font(.body.monospaced().weight(.semibold))
                                    .foregroundStyle(.primary)
                                if let ns = currentKV[key]?.namespaceId {
                                    Text(ns)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                            Spacer()
                            HIGBadge(.custom(color: .purple, text: "KV"), isCompact: true)
                        }
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = key
                                HIGFeedback.success()
                                HIGFeedback.impact(.light)
                            } label: {
                                Label("Copy Binding Name", systemImage: "doc.on.doc")
                            }
                            Button(role: .destructive) {
                                resourceToUnbind = (name: key, type: "kv")
                                showingUnbindAlert = true
                            } label: {
                                Label("Unbind KV Namespace", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                resourceToUnbind = (name: key, type: "kv")
                                showingUnbindAlert = true
                            } label: {
                                Label("Unbind", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            // MARK: - 4. D1 Databases
            if !currentD1.isEmpty {
                Section(header: Text("D1 Databases (\(currentD1.count))")) {
                    ForEach(Array(currentD1.keys.sorted()), id: \.self) { key in
                        HStack(spacing: 12) {
                            Image(systemName: "cylinder.split.1x2.fill")
                                .font(.body)
                                .foregroundStyle(.indigo)
                                .frame(width: 32, height: 32)
                                .background(Color.indigo.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .accessibilityHidden(true)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(key)
                                    .font(.body.monospaced().weight(.semibold))
                                    .foregroundStyle(.primary)
                                if let id = currentD1[key]?.id {
                                    Text(id)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                            Spacer()
                            HIGBadge(.custom(color: .indigo, text: "D1"), isCompact: true)
                        }
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = key
                                HIGFeedback.success()
                                HIGFeedback.impact(.light)
                            } label: {
                                Label("Copy Binding Name", systemImage: "doc.on.doc")
                            }
                            Button(role: .destructive) {
                                resourceToUnbind = (name: key, type: "d1")
                                showingUnbindAlert = true
                            } label: {
                                Label("Unbind D1 Database", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                resourceToUnbind = (name: key, type: "d1")
                                showingUnbindAlert = true
                            } label: {
                                Label("Unbind", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            // MARK: - 5. R2 Buckets
            if !currentR2.isEmpty {
                Section(header: Text("R2 Buckets (\(currentR2.count))")) {
                    ForEach(Array(currentR2.keys.sorted()), id: \.self) { key in
                        HStack(spacing: 12) {
                            Image(systemName: "externaldrive.fill")
                                .font(.body)
                                .foregroundStyle(.blue)
                                .frame(width: 32, height: 32)
                                .background(Color.blue.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .accessibilityHidden(true)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(key)
                                    .font(.body.monospaced().weight(.semibold))
                                    .foregroundStyle(.primary)
                                if let bucket = currentR2[key]?.name {
                                    Text(bucket)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                            Spacer()
                            HIGBadge(.custom(color: .blue, text: "R2"), isCompact: true)
                        }
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = key
                                HIGFeedback.success()
                                HIGFeedback.impact(.light)
                            } label: {
                                Label("Copy Binding Name", systemImage: "doc.on.doc")
                            }
                            Button(role: .destructive) {
                                resourceToUnbind = (name: key, type: "r2")
                                showingUnbindAlert = true
                            } label: {
                                Label("Unbind R2 Bucket", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                resourceToUnbind = (name: key, type: "r2")
                                showingUnbindAlert = true
                            } label: {
                                Label("Unbind", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            // MARK: - 6. AI Models
            if !currentAI.isEmpty {
                Section(header: Text("Workers AI (\(currentAI.count))")) {
                    ForEach(Array(currentAI.keys.sorted()), id: \.self) { key in
                        HStack(spacing: 12) {
                            Image(systemName: "brain.head.profile")
                                .font(.body)
                                .foregroundStyle(.pink)
                                .frame(width: 32, height: 32)
                                .background(Color.pink.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .accessibilityHidden(true)
                            
                            Text(key)
                                .font(.body.monospaced().weight(.semibold))
                                .foregroundStyle(.primary)
                            Spacer()
                            HIGBadge(.custom(color: .pink, text: "AI"), isCompact: true)
                        }
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = key
                                HIGFeedback.success()
                                HIGFeedback.impact(.light)
                            } label: {
                                Label("Copy Binding Name", systemImage: "doc.on.doc")
                            }
                            Button(role: .destructive) {
                                resourceToUnbind = (name: key, type: "ai")
                                showingUnbindAlert = true
                            } label: {
                                Label("Unbind AI Binding", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                resourceToUnbind = (name: key, type: "ai")
                                showingUnbindAlert = true
                            } label: {
                                Label("Unbind", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            // MARK: - 7. Compatibility Settings
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
        .listStyle(.insetGrouped)
    }
    
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
            HIGFeedback.success()
            HIGFeedback.success()
        } catch {
            HIGFeedback.error()
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
            HIGFeedback.success()
        } catch {
            HIGFeedback.error()
        }
        isDeleting = false
    }
}

// MARK: - EditVarWrapper Helper

private struct EditVarWrapper: Identifiable {
    var id: String { name }
    let name: String
    let value: PagesEnvVarValue
}

// MARK: - PagesAddVariableSheetView (Inlined & Cohesive)

struct PagesAddVariableSheetView: View {
    let accountId: String
    let projectName: String
    let environment: String
    let existingEnvVars: [String: PagesEnvVarValue]
    var initialName: String = ""
    var initialValue: String = ""
    var initialIsSecret: Bool = false
    let onSave: ([String: PagesEnvVarValue]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var value: String
    @State private var isSecret: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    init(
        accountId: String,
        projectName: String,
        environment: String,
        existingEnvVars: [String: PagesEnvVarValue],
        initialName: String = "",
        initialValue: String = "",
        initialIsSecret: Bool = false,
        onSave: @escaping ([String: PagesEnvVarValue]) -> Void
    ) {
        self.accountId = accountId
        self.projectName = projectName
        self.environment = environment
        self.existingEnvVars = existingEnvVars
        self.initialName = initialName
        self.initialValue = initialValue
        self.initialIsSecret = initialIsSecret
        self.onSave = onSave
        _name = State(initialValue: initialName)
        _value = State(initialValue: initialValue)
        _isSecret = State(initialValue: initialIsSecret)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Variable Details")) {
                    TextField("Variable Name (e.g. API_KEY)", text: $name)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .disabled(!initialName.isEmpty)
                    
                    TextField("Value", text: $value)
                        .autocorrectionDisabled()
                    
                    Toggle("Encrypt Value (Secret)", isOn: $isSecret)
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
            .navigationTitle(initialName.isEmpty ? "Add Variable" : "Edit Variable")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            var updated = existingEnvVars
                            let varKey = name.trimmingCharacters(in: .whitespaces)
                            let varVal = PagesEnvVarValue(
                                value: value,
                                type: isSecret ? "secret_text" : "plain_text"
                            )
                            updated[varKey] = varVal
                            do {
                                try await PagesService.shared.updatePagesEnvVars(
                                    accountId: accountId,
                                    projectName: projectName,
                                    environment: environment,
                                    envVars: updated
                                )
                                onSave(updated)
                                HIGFeedback.success()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}

// MARK: - PagesAttachResourceBindingSheetView (Inlined & Cohesive)

struct PagesAttachResourceBindingSheetView: View {
    let accountId: String
    let projectName: String
    let environment: String
    let existingKV: [String: PagesKVBinding]
    let existingD1: [String: PagesD1Binding]
    let existingR2: [String: PagesR2Binding]
    let existingAI: [String: PagesAIBinding]
    let onSave: (String, [String: PagesKVBinding], [String: PagesD1Binding], [String: PagesR2Binding], [String: PagesAIBinding]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var bindingType = "kv" // "kv" | "d1" | "r2" | "ai"
    @State private var variableName = ""
    @State private var resourceTarget = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    let bindingTypes = [
        ("KV Namespace", "kv"),
        ("D1 Database", "d1"),
        ("R2 Bucket", "r2"),
        ("Workers AI", "ai")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Resource Type")) {
                    Picker("Binding Type", selection: $bindingType) {
                        ForEach(bindingTypes, id: \.1) { label, value in
                            Text(label).tag(value)
                        }
                    }
                }
                
                Section(header: Text("Binding Configuration")) {
                    TextField("Variable Name (e.g. DB or MY_BUCKET)", text: $variableName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    
                    if bindingType != "ai" {
                        TextField(resourceTargetPlaceholder, text: $resourceTarget)
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
                            var updatedKV = existingKV
                            var updatedD1 = existingD1
                            var updatedR2 = existingR2
                            var updatedAI = existingAI
                            let varKey = variableName.trimmingCharacters(in: .whitespaces)
                            let target = resourceTarget.trimmingCharacters(in: .whitespaces)
                            
                            switch bindingType {
                            case "kv": updatedKV[varKey] = PagesKVBinding(namespaceId: target)
                            case "d1": updatedD1[varKey] = PagesD1Binding(id: target)
                            case "r2": updatedR2[varKey] = PagesR2Binding(name: target)
                            case "ai": updatedAI[varKey] = PagesAIBinding(projectId: "")
                            default: break
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
                                onSave(environment, updatedKV, updatedD1, updatedR2, updatedAI)
                                HIGFeedback.success()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(variableName.trimmingCharacters(in: .whitespaces).isEmpty || (bindingType != "ai" && resourceTarget.trimmingCharacters(in: .whitespaces).isEmpty) || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
    
    private var resourceTargetPlaceholder: String {
        switch bindingType {
        case "kv": return "KV Namespace ID"
        case "d1": return "D1 Database ID"
        case "r2": return "R2 Bucket Name"
        default: return "Target Identifier"
        }
    }
}

