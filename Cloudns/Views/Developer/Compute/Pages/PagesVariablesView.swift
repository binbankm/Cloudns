import SwiftUI

// MARK: - PagesVariablesView
// Apple HIG Compliant Cloudflare Pages Environment Variables & Secrets Vault

struct PagesVariablesView: View {
    let accountId: String
    let project: PagesProject
    @State private var selectedEnv = "production" // "production" | "preview"
    
    // Environment Variables State
    @State private var productionEnvVars: [String: PagesEnvVarValue] = [:]
    @State private var previewEnvVars: [String: PagesEnvVarValue] = [:]
    
    // Sheets & Alerts
    @State private var showingAddVariableSheet = false
    @State private var variableToEdit: (name: String, value: PagesEnvVarValue)?
    @State private var varNameToDelete: String?
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    
    init(accountId: String, project: PagesProject) {
        self.accountId = accountId
        self.project = project
        _productionEnvVars = State(initialValue: project.deploymentConfigs?.production?.envVars ?? [:])
        _previewEnvVars = State(initialValue: project.deploymentConfigs?.preview?.envVars ?? [:])
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
    
    private var prodCount: Int { productionEnvVars.count }
    private var prevCount: Int { previewEnvVars.count }
    
    var body: some View {
        VStack(spacing: 0) {
            envPickerBar
            contentList
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Variables & Secrets")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddVariableSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Variable or Secret")
                .higTouchTarget(44)
            }
        }
        .sheet(isPresented: $showingAddVariableSheet) {
            PagesAddVariableSheetView(
                accountId: accountId,
                projectName: project.name,
                environment: selectedEnv,
                existingEnvVars: currentEnvVars,
                onSave: { updated in
                    if selectedEnv == "production" {
                        productionEnvVars = updated
                    } else {
                        previewEnvVars = updated
                    }
                }
            )
            .higToast()
        }
        .sheet(item: Binding(
            get: { variableToEdit.map { EditVarItem(id: $0.name, name: $0.name, value: $0.value) } },
            set: { val in
                if let val {
                    variableToEdit = (val.name, val.value)
                } else {
                    variableToEdit = nil
                }
            }
        )) { item in
            PagesAddVariableSheetView(
                accountId: accountId,
                projectName: project.name,
                environment: selectedEnv,
                existingEnvVars: currentEnvVars,
                initialName: item.name,
                initialValue: item.value.value ?? "",
                initialIsSecret: item.value.isSecret,
                onSave: { updated in
                    if selectedEnv == "production" {
                        productionEnvVars = updated
                    } else {
                        previewEnvVars = updated
                    }
                }
            )
            .higToast()
        }
        .confirmationDialog("Delete Variable", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
            if let name = varNameToDelete {
                Button("Delete '\(name)'", role: .destructive) {
                    deleteVariable(name: name)
                }
            }
            Button("Cancel", role: .cancel) {
                varNameToDelete = nil
            }
        } message: {
            if let name = varNameToDelete {
                Text("Are you sure you want to delete environment variable '\(name)' from \(selectedEnv.capitalized) environment?")
            }
        }
    }
    
    @ViewBuilder
    private var envPickerBar: some View {
        Picker("Environment", selection: $selectedEnv) {
            Text("Production (\(prodCount))").tag("production")
            Text("Preview (\(prevCount))").tag("preview")
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, HIGTokens.Spacing.md)
        .padding(.vertical, HIGTokens.Spacing.sm)
        .background(Color(.systemGroupedBackground))
        .onChange(of: selectedEnv) { _ in
            HIGFeedback.selection()
        }
    }
    
    @ViewBuilder
    private var contentList: some View {
        List {
            if !plainVariables.isEmpty {
                Section(header: Text("Plaintext Variables (\(plainVariables.count))")) {
                    ForEach(Array(plainVariables.keys.sorted()), id: \.self) { key in
                        if let val = plainVariables[key] {
                            Button {
                                HIGFeedback.impact(.light)
                                variableToEdit = (key, val)
                            } label: {
                                variableRow(key: key, value: val)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = key
                                    ToastManager.shared.showCopied("Variable Name Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Name", systemImage: "doc.on.doc")
                                }
                                
                                if let v = val.value, !v.isEmpty {
                                    Button {
                                        UIPasteboard.general.string = v
                                        ToastManager.shared.showCopied("Variable Value Copied")
                                        HIGFeedback.copied()
                                    } label: {
                                        Label("Copy Value", systemImage: "doc.on.doc.fill")
                                    }
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    HIGFeedback.impact(.medium)
                                    varNameToDelete = key
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HIGFeedback.impact(.medium)
                                    varNameToDelete = key
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(HIGColors.error)
                            }
                        }
                    }
                }
            }
            
            if !secretVariables.isEmpty {
                Section(header: Text("Encrypted Secrets (\(secretVariables.count))")) {
                    ForEach(Array(secretVariables.keys.sorted()), id: \.self) { key in
                        if let val = secretVariables[key] {
                            Button {
                                HIGFeedback.impact(.light)
                                variableToEdit = (key, val)
                            } label: {
                                variableRow(key: key, value: val)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = key
                                    ToastManager.shared.showCopied("Secret Name Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Name", systemImage: "doc.on.doc")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    HIGFeedback.impact(.medium)
                                    varNameToDelete = key
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete Secret", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HIGFeedback.impact(.medium)
                                    varNameToDelete = key
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(HIGColors.error)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if currentEnvVars.isEmpty {
                HIGContentState(
                    .empty(
                        title: "No Variables or Secrets",
                        systemImage: "key.fill",
                        description: "No environment variables or encrypted secrets configured for \(selectedEnv.capitalized) environment.",
                        actionTitle: "Add Variable or Secret",
                        action: { showingAddVariableSheet = true }
                    )
                )
            }
        }
    }
    
    @ViewBuilder
    private func variableRow(key: String, value: PagesEnvVarValue) -> some View {
        HStack(spacing: HIGTokens.Spacing.md) {
            ListRowIcon(
                icon: value.isSecret ? "lock.fill" : "textformat",
                color: value.isSecret ? .purple : .blue
            )
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                HStack(spacing: HIGTokens.Spacing.xs + 2) {
                    Text(key)
                        .font(HIGTypography.body.monospaced().weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    if value.isSecret {
                        HIGBadge(.custom(color: .purple, text: "Secret"), isCompact: true)
                    }
                }
                
                if value.isSecret {
                    Text("••••••••••••••••")
                        .font(HIGTypography.caption.monospaced())
                        .foregroundStyle(.secondary)
                } else if let txt = value.value, !txt.isEmpty {
                    Text(txt)
                        .font(HIGTypography.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(HIGTypography.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
        .contentShape(Rectangle())
    }
    
    private func deleteVariable(name: String) {
        guard !isDeleting else { return }
        isDeleting = true
        
        Task {
            var updated = currentEnvVars
            updated.removeValue(forKey: name)
            
            do {
                try await PagesService.shared.updatePagesEnvVars(
                    accountId: accountId,
                    projectName: project.name,
                    environment: selectedEnv,
                    envVars: updated
                )
                
                await MainActor.run {
                    if selectedEnv == "production" {
                        productionEnvVars.removeValue(forKey: name)
                    } else {
                        previewEnvVars.removeValue(forKey: name)
                    }
                    varNameToDelete = nil
                    isDeleting = false
                    ToastManager.shared.showSuccess("Variable Deleted", icon: "trash.fill")
                    HIGFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    varNameToDelete = nil
                    ToastManager.shared.showError("Failed to Delete Variable")
                    HIGFeedback.error()
                }
            }
        }
    }
}

// MARK: - Edit Item Wrapper

private struct EditVarItem: Identifiable {
    let id: String
    let name: String
    let value: PagesEnvVarValue
}

// MARK: - PagesAddVariableSheetView (Reusable across Pages module)

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
                        .font(HIGTypography.body.monospaced())
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .disabled(!initialName.isEmpty)
                    
                    TextField("Value", text: $value)
                        .font(HIGTypography.body)
                        .autocorrectionDisabled()
                    
                    Toggle("Encrypt Value (Secret)", isOn: $isSecret)
                }
                
                if let err = errorMessage {
                    Section {
                        HStack(spacing: HIGTokens.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(HIGColors.error)
                            Text(verbatim: err)
                                .font(HIGTypography.caption)
                                .foregroundStyle(HIGColors.error)
                        }
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
                        .higTouchTarget(44)
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
                                ToastManager.shared.showSuccess("Variable Saved", icon: "key.fill")
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
                    .higTouchTarget(44)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
