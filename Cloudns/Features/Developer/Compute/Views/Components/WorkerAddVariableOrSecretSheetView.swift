import SwiftUI

// MARK: - WorkerAddVariableOrSecretSheetView

struct WorkerAddVariableOrSecretSheetView: View {
    @ObservedObject var viewModel: WorkerSecretsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isSecret = false
    @State private var itemName = ""
    @State private var itemValue = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Type")) {
                    Picker("Type", selection: $isSecret) {
                        Text("Plaintext Variable").tag(false)
                        Text("Encrypted Secret").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text(isSecret ? "Secret Key Name" : "Variable Key Name")) {
                    TextField("KEY_NAME", text: $itemName)
                        .keyboardType(.asciiCapable)
                        .submitLabel(.done)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                
                Section(
                    header: Text(isSecret ? "Secret Value (Encrypted)" : "Variable Value (Plaintext)"),
                    footer: Text(isSecret ? "Secrets cannot be viewed after saving. Use for API keys, tokens and passwords." : "Plaintext variables can be read, viewed, and modified at any time.")
                ) {
                    if isSecret {
                        SecureField("Secret Value", text: $itemValue)
                            .textContentType(.password)
                            .keyboardType(.asciiCapable)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                    } else {
                        TextField("Variable Value", text: $itemValue, axis: .vertical)
                            .lineLimit(2...5)
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
            .navigationTitle(isSecret ? "Add Secret" : "Add Variable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(itemName.trimmingCharacters(in: .whitespaces).isEmpty || itemValue.isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
    
    private func save() {
        isSaving = true
        errorMessage = nil
        let name = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                if isSecret {
                    try await viewModel.saveSecret(name: name, value: itemValue)
                    viewModel.selectedTab = "secrets"
                } else {
                    try await viewModel.savePlainVariable(name: name, value: itemValue)
                    viewModel.selectedTab = "variables"
                }
                HapticManager.impact(.medium)
                CloudnsToastManager.shared.showSuccess("Saved", message: name)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
