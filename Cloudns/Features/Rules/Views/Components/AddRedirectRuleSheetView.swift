import SwiftUI

// MARK: - AddRedirectRuleSheetView

struct AddRedirectRuleSheetView: View {
    // MARK: - Properties
    let zoneId: String
    @ObservedObject var viewModel: RedirectRulesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var ruleDescription = ""
    @State private var expression = "http.request.uri.path eq \"/old-path\""
    @State private var targetUrl = "https://example.com/new-path"
    @State private var statusCode = 301
    @State private var preserveQueryString = false
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Rule Description")) {
                    TextField("Rule Name", text: $ruleDescription)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                }
                
                Section(header: Text("Matching Expression"), footer: Text("Cloudflare wirefilter expression defining which incoming requests trigger redirection.")) {
                    TextField("Expression", text: $expression)
                        .font(.footnote.monospaced())
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                }
                
                Section(header: Text("Redirect Target & Code")) {
                    TextField("Target URL (e.g. https://example.com/new)", text: $targetUrl)
                        .font(.footnote)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                    
                    Picker("Status Code", selection: $statusCode) {
                        Text("301 - Moved Permanently").tag(301)
                        Text("302 - Found (Temporary)").tag(302)
                        Text("307 - Temporary Redirect").tag(307)
                        Text("308 - Permanent Redirect").tag(308)
                    }
                    
                    Toggle("Preserve Query String", isOn: $preserveQueryString)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(CloudnsColor.danger)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Redirect Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            errorMessage = nil
                            let success = await viewModel.createRule(
                                zoneId: zoneId,
                                description: ruleDescription,
                                expression: expression,
                                targetUrl: targetUrl,
                                statusCode: statusCode,
                                preserveQueryString: preserveQueryString
                            )
                            if success {
                                dismiss()
                            }
                            isCreating = false
                        }
                    }
                    .disabled(ruleDescription.trimmingCharacters(in: .whitespaces).isEmpty || expression.trimmingCharacters(in: .whitespaces).isEmpty || targetUrl.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
            .toastContainer()
        }
    }
}
