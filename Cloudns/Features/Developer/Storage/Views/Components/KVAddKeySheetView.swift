import SwiftUI

// MARK: - KVAddKeySheetView

struct KVAddKeySheetView: View {
    @ObservedObject var viewModel: KVNamespaceDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var key: String = ""
    @State private var value: String = ""
    @State private var expirationTtl: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Key Details")) {
                    TextField("Key (e.g. user:12345:profile)", text: $key)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    
                    TextField("Expiration TTL (seconds, optional)", text: $expirationTtl)
                        .keyboardType(.numberPad)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                
                Section(header: Text("Value")) {
                    TextEditor(text: $value)
                        .frame(minHeight: 120)
                        .font(.body.monospaced())
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
            .navigationTitle("Add Key / Value")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            do {
                                let ttl = Int(expirationTtl)
                                try await viewModel.saveKey(key: key.trimmingCharacters(in: .whitespacesAndNewlines), value: value, ttl: ttl)
                                CloudnsToastManager.shared.showSuccess("Key Saved", message: key)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isSaving = false
                        }
                    }
                    .disabled(key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                    .overlay {
                        if isSaving {
                            ProgressView()
                        }
                    }
                }
            }
            .interactiveDismissDisabled(isSaving)
            .toastContainer()
        }
    }
}
