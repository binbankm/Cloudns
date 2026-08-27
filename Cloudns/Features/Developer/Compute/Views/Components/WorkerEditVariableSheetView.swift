import SwiftUI

// MARK: - WorkerEditVariableSheetView

struct WorkerEditVariableSheetView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: WorkerSecretsViewModel
    let variable: WorkerBinding
    @Environment(\.dismiss) private var dismiss
    
    @State private var variableValue: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    init(viewModel: WorkerSecretsViewModel, variable: WorkerBinding) {
        self.viewModel = viewModel
        self.variable = variable
        _variableValue = State(initialValue: variable.text ?? "")
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Variable Key")) {
                    Text(variable.name)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                
                Section(header: Text("Variable Value (Plaintext)")) {
                    TextField("Value", text: $variableValue, axis: .vertical)
                        .lineLimit(3...6)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
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
            .navigationTitle("Edit Variable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
    
    // MARK: - Actions
    private func save() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await viewModel.savePlainVariable(name: variable.name, value: variableValue)
                HapticManager.impact(.medium)
                CloudnsToastManager.shared.showSuccess("Updated", message: variable.name)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
