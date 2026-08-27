import SwiftUI

// MARK: - WorkerCreateSheetView

struct WorkerCreateSheetView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: WorkersViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var scriptName: String = ""
    @State private var code: String = """
    export default {
      async fetch(request, env, ctx) {
        return new Response("Hello Cloudflare Worker!");
      },
    };
    """
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Worker Information")) {
                    TextField("Worker Name (e.g. api-service)", text: $scriptName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                
                Section(header: Text("Initial Code (ES Module)")) {
                    CloudnsCodeEditorView(text: $code)
                        .frame(minHeight: 180)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(CloudnsColor.danger)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Create Worker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Deploy") {
                        Task {
                            isCreating = true
                            errorMessage = nil
                            do {
                                try await viewModel.createWorker(name: scriptName.trimmingCharacters(in: .whitespacesAndNewlines), code: code)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isCreating = false
                        }
                    }
                    .disabled(scriptName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
            .toastContainer()
        }
    }
}
