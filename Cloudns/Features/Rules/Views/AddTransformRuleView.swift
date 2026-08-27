import SwiftUI

struct AddTransformRuleView: View {
    // MARK: - Properties
    let zoneId: String
    let initialPhase: String
    @ObservedObject var viewModel: TransformRulesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var phase: String
    @State private var ruleName = ""
    @State private var expression = "(http.request.uri.path contains \"/\")"
    
    // URL Rewrite States
    @State private var rewritePath = ""
    @State private var rewriteQuery = ""
    
    // Header Transform States
    @State private var headerName = ""
    @State private var headerOperation = "set" // "set" or "remove"
    @State private var headerValue = ""
    
    @State private var isSubmitting = false
    @FocusState private var focusedField: String?
    
    init(zoneId: String, initialPhase: String = "http_request_transform", viewModel: TransformRulesViewModel) {
        self.zoneId = zoneId
        self.initialPhase = initialPhase
        self.viewModel = viewModel
        _phase = State(initialValue: initialPhase)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Rule Type")) {
                    Picker("Type", selection: $phase) {
                        Text("URL Rewrite").tag("http_request_transform")
                        Text("Request Header").tag("http_request_late_transform")
                        Text("Response Header").tag("http_response_headers_transform")
                    }
                }
                
                Section(header: Text("Rule Details")) {
                    TextField("Rule Name (e.g. Modify X-Custom-Header)", text: $ruleName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: "name")
                        .onSubmit { focusedField = "expression" }
                }
                
                Section(header: Text("Matching Expression"), footer: Text("Cloudflare wirefilter expression defining matching incoming traffic.")) {
                    TextField("Expression", text: $expression)
                        .font(.footnote.monospaced())
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: "expression")
                }
                
                if phase == "http_request_transform" {
                    Section(header: Text("URI Path & Query Rewrite"), footer: Text("Rewrites incoming URI path and query string before reaching origin server.")) {
                        TextField("Static Path (e.g. /api/v2)", text: $rewritePath)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: "rewritePath")
                        TextField("Query String (Optional)", text: $rewriteQuery)
                            .submitLabel(.done)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: "rewriteQuery")
                    }
                } else {
                    Section(header: Text("HTTP Header Action"), footer: Text(phase == "http_request_late_transform" ? "Modifies HTTP request headers sent to the origin." : "Modifies HTTP response headers returned to the client.")) {
                        TextField("Header Name (e.g. X-Frame-Options)", text: $headerName)
                            .keyboardType(.asciiCapable)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: "headerName")
                        
                        Picker("Operation", selection: $headerOperation) {
                            Text("Set Static Value").tag("set")
                            Text("Remove Header").tag("remove")
                        }
                        
                        if headerOperation == "set" {
                            TextField("Header Value (e.g. DENY)", text: $headerValue)
                                .keyboardType(.asciiCapable)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: "headerValue")
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .centerConstrainedWidth(maxWidth: 840)
            .navigationTitle("New Transform Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticManager.impact(.medium)
                        Task {
                            await submitRule()
                        }
                    }
                    .disabled(isFormInvalid || isSubmitting)
                }
            }
            .interactiveDismissDisabled(isSubmitting)
            .overlay(
                Group {
                    if isSubmitting {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Saving...")
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            )
            .toastContainer()
        }
    }
    
    private var isFormInvalid: Bool {
        if ruleName.isEmpty || expression.isEmpty { return true }
        if phase == "http_request_transform" {
            return rewritePath.isEmpty && rewriteQuery.isEmpty
        } else {
            if headerName.isEmpty { return true }
            if headerOperation == "set" && headerValue.isEmpty { return true }
        }
        return false
    }
    
    // MARK: - Actions
    private func submitRule() async {
        isSubmitting = true
        
        let success: Bool
        if phase == "http_request_transform" {
            success = await viewModel.createRewriteRule(
                zoneId: zoneId,
                expression: expression,
                description: ruleName,
                enabled: true,
                rewritePath: rewritePath,
                rewriteQuery: rewriteQuery.isEmpty ? nil : rewriteQuery
            )
        } else {
            success = await viewModel.createHeaderRule(
                zoneId: zoneId,
                phase: phase,
                expression: expression,
                description: ruleName,
                enabled: true,
                headerName: headerName.trimmingCharacters(in: .whitespaces),
                operation: headerOperation,
                value: headerOperation == "set" ? headerValue : nil
            )
        }
        
        isSubmitting = false
        if success {
            dismiss()
        }
    }
}
