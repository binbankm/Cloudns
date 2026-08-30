import SwiftUI

// MARK: - PagesVariablesView (Dedicated Variables & Secrets)

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
            // Environment Segmented Switcher
            Picker("Environment", selection: $selectedEnv) {
                Text("Production (\(prodCount))").tag("production")
                Text("Preview (\(prevCount))").tag("preview")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            .onChange(of: selectedEnv) { _ in
                HIGFeedback.selection()
            }
            
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HIGFeedback.impact(.medium)
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HIGFeedback.impact(.medium)
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
        HStack(spacing: 12) {
            ListRowIcon(
                icon: value.isSecret ? "lock.fill" : "textformat",
                color: value.isSecret ? .purple : .blue,
                size: 28,
                cornerRadius: 6
            )
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(key)
                        .font(.body.monospaced().weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    if value.isSecret {
                        HIGBadge(.custom(color: .purple, text: "Secret"), isCompact: true)
                    }
                }
                
                if value.isSecret {
                    Text("••••••••••••••••")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                } else if let txt = value.value, !txt.isEmpty {
                    Text(txt)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 3)
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
                    ToastManager.shared.showError("Failed to delete variable")
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
