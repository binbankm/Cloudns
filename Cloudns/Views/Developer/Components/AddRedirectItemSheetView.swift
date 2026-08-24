import SwiftUI

// MARK: - AddRedirectItemSheetView

struct AddRedirectItemSheetView: View {
    let accountId: String
    let listId: String
    let onAdded: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var sourceUrl = ""
    @State private var targetUrl = ""
    @State private var statusCode = 301
    @State private var preserveQueryString = true
    @State private var subpathMatching = false
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Source URL")) {
                    TextField("https://old.example.com/page", text: $sourceUrl)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                }
                
                Section(header: Text("Target URL")) {
                    TextField("https://new.example.com/target", text: $targetUrl)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                
                Section(header: Text("Settings")) {
                    Picker("Status Code", selection: $statusCode) {
                        Text("301 Permanent Redirect").tag(301)
                        Text("302 Temporary Redirect").tag(302)
                        Text("307 Temporary Redirect").tag(307)
                        Text("308 Permanent Redirect").tag(308)
                    }
                    
                    Toggle("Preserve Query String", isOn: $preserveQueryString)
                    Toggle("Subpath Matching", isOn: $subpathMatching)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Redirect Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            isSubmitting = true
                            let item = RedirectItemDetail(
                                sourceUrl: sourceUrl.trimmingCharacters(in: .whitespacesAndNewlines),
                                targetUrl: targetUrl.trimmingCharacters(in: .whitespacesAndNewlines),
                                statusCode: statusCode,
                                preserveQueryString: preserveQueryString,
                                includeSubdomains: false,
                                subpathMatching: subpathMatching,
                                preservePathSuffix: false
                            )
                            do {
                                _ = try await BulkRedirectService.shared.createRedirectListItems(accountId: accountId, listId: listId, items: [item])
                                ToastManager.shared.showSuccess("Item Added")
                                onAdded()
                                dismiss()
                            } catch {
                                ToastManager.shared.showError("Add Failed", message: error.localizedDescription)
                            }
                            isSubmitting = false
                        }
                    }
                    .disabled(sourceUrl.isEmpty || targetUrl.isEmpty || isSubmitting)
                }
            }
            .interactiveDismissDisabled(isSubmitting)
            .toastContainer()
        }
    }
}
