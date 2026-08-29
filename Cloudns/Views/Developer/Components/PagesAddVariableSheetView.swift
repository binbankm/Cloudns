import SwiftUI

// MARK: - PagesAddVariableSheetView

struct PagesAddVariableSheetView: View {
    let accountId: String
    let projectName: String
    let environment: String
    let existingEnvVars: [String: PagesEnvVarValue]
    let onSaved: ([String: PagesEnvVarValue]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var varName: String = ""
    @State private var varValue: String = ""
    @State private var isSecret: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    
    private let isEditing: Bool
    
    init(
        accountId: String,
        projectName: String,
        environment: String,
        existingEnvVars: [String: PagesEnvVarValue],
        initialName: String = "",
        initialValue: String = "",
        initialIsSecret: Bool = false,
        onSaved: @escaping ([String: PagesEnvVarValue]) -> Void
    ) {
        self.accountId = accountId
        self.projectName = projectName
        self.environment = environment
        self.existingEnvVars = existingEnvVars
        self.onSaved = onSaved
        self.isEditing = !initialName.isEmpty
        _varName = State(initialValue: initialName)
        _varValue = State(initialValue: initialValue)
        _isSecret = State(initialValue: initialIsSecret)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Target Environment")) {
                    HStack {
                        Text("Environment")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(environment.capitalized)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(environment == "production" ? .green : .blue)
                    }
                }
                
                Section(header: Text("Variable Details")) {
                    TextField("Variable Name (e.g. API_KEY)", text: $varName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .disabled(isEditing)
                        .submitLabel(.next)
                    
                    Toggle(isOn: $isSecret) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Encrypt as Secret")
                                .font(.body)
                            Text("Secret values are encrypted at rest and cannot be viewed once saved.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Value")) {
                    if isSecret {
                        SecureField("Secret Value", text: $varValue)
                            .autocorrectionDisabled()
                    } else {
                        TextEditor(text: $varValue)
                            .frame(minHeight: 90)
                            .font(.body.monospaced())
                    }
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isEditing ? "Edit Variable" : "Add Variable")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveVariable() }
                    }
                    .disabled(varName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                    .overlay {
                        if isSaving { ProgressView() }
                    }
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
    
    private func saveVariable() async {
        let cleanName = varName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        
        isSaving = true
        errorMessage = nil
        HapticManager.impact(.medium)
        
        var updated = existingEnvVars
        updated[cleanName] = PagesEnvVarValue(value: varValue, type: isSecret ? "secret_text" : "plain_text")
        
        do {
            try await PagesService.shared.updatePagesEnvVars(
                accountId: accountId,
                projectName: projectName,
                environment: environment,
                envVars: updated
            )
            HapticManager.notification(.success)
            ToastManager.shared.showSuccess("Variable Saved", message: "\(cleanName) (\(environment.capitalized))")
            onSaved(updated)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
