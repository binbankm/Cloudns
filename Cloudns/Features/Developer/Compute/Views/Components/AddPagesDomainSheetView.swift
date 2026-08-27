import SwiftUI

// MARK: - Add Pages Domain Sheet

struct AddPagesDomainSheetView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: PagesProjectDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var domainName = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Domain Name"), footer: Text("Enter a fully qualified domain name (e.g. docs.example.com or example.com).")) {
                    TextField("sub.example.com", text: $domainName)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .font(.body)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(CloudnsColor.danger)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Custom Domain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            do {
                                let trimmed = domainName.trimmingCharacters(in: .whitespacesAndNewlines)
                                try await viewModel.addDomain(name: trimmed)
                                HapticManager.impact(.medium)
                                CloudnsToastManager.shared.showSuccess("Domain Added", message: trimmed)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isSaving = false
                        }
                    }
                    .disabled(domainName.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .toastContainer()
        }
    }
}
