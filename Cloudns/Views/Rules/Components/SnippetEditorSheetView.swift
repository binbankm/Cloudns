import SwiftUI

// MARK: - SnippetEditorSheetView

struct SnippetEditorSheetView: View {
    let zoneId: String
    let existingSnippet: SnippetItem?
    @ObservedObject var viewModel: SnippetsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var snippetName = ""
    @State private var code = """
    export default {
      async fetch(request) {
        // Modify request or response on the edge
        return fetch(request);
      }
    };
    """
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Snippet Name"), footer: Text("Allowed characters: letters, numbers, and underscores.")) {
                    TextField("my_snippet", text: $snippetName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .disabled(existingSnippet != nil)
                }
                
                Section(header: Text("JavaScript Code (ES Module)")) {
                    TextEditor(text: $code)
                        .font(.footnote)
                        .frame(minHeight: 180)
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
            .navigationTitle(existingSnippet?.snippet_name ?? "New Snippet")
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
                            let success = await viewModel.saveSnippet(
                                zoneId: zoneId,
                                name: snippetName,
                                code: code
                            )
                            if success {
                                dismiss()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(snippetName.trimmingCharacters(in: .whitespaces).isEmpty || code.isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .task {
                if let ex = existingSnippet {
                    snippetName = ex.snippet_name
                    if let fetched = await viewModel.loadSnippetContent(zoneId: zoneId, name: ex.snippet_name), !fetched.isEmpty {
                        code = fetched
                    }
                }
            }
            .toastContainer()
        }
    }
}
