import SwiftUI

// MARK: - CreateBulkRedirectListSheetView

struct CreateBulkRedirectListSheetView: View {
    @ObservedObject var viewModel: BulkRedirectsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("List Name")) {
                    TextField("marketing-redirects", text: $name)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                
                Section(header: Text("Description (Optional)")) {
                    TextField("Redirects for domain migration", text: $description)
                        .submitLabel(.done)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Redirect List")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isSubmitting = true
                            let clean = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                            let success = await viewModel.createList(name: clean, description: description.isEmpty ? nil : description)
                            if success { dismiss() }
                            isSubmitting = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
            .interactiveDismissDisabled(isSubmitting)
            .toastContainer()
        }
    }
}
