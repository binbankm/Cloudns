import SwiftUI

struct AddWAFRuleView: View {
    // MARK: - Properties
    let zoneId: String
    @ObservedObject var viewModel: WAFViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var ruleName = ""
    @State private var action = "block"
    @State private var editorMode = 0 // 0: Visual Builder, 1: Raw Expression
    
    // Visual Builder states
    @State private var field = "ip.src"
    @State private var operatorType = "eq"
    @State private var value = ""
    
    // Raw Expression state
    @State private var rawExpression = ""
    
    @State private var isSubmitting = false
    @FocusState private var focusedField: FocusableField?
    
    enum FocusableField {
        case name, value, rawExpression
    }
    
    let actions = [
        ("Block", "block"),
        ("Managed Challenge", "managed_challenge"),
        ("JS Challenge", "js_challenge"),
        ("Interactive Challenge", "challenge"),
        ("Log", "log"),
        ("Skip", "skip")
    ]
    
    let fields = [
        ("IP Address", "ip.src"),
        ("Country/Region", "ip.geoip.country"),
        ("ASN Number", "ip.geoip.asnum"),
        ("URI Path", "http.request.uri.path"),
        ("URI Query String", "http.request.uri.query"),
        ("HTTP Method", "http.request.method"),
        ("User Agent", "http.user_agent"),
        ("Hostname", "http.host"),
        ("Referer Header", "http.request.headers[\"referer\"]"),
        ("Threat Score (0-100)", "cf.threat_score")
    ]
    
    let operatorsForString = [
        ("Equals", "eq"),
        ("Does not equal", "ne"),
        ("Contains", "contains"),
        ("Does not contain", "not contains"),
        ("Starts with", "starts_with"),
        ("Ends with", "ends_with")
    ]
    
    let operatorsForIP = [
        ("Equals", "eq"),
        ("Does not equal", "ne"),
        ("In list", "in")
    ]
    
    let operatorsForNumber = [
        ("Equals", "eq"),
        ("Greater than", "gt"),
        ("Greater than or equal", "ge"),
        ("Less than", "lt"),
        ("Less than or equal", "le")
    ]
    
    var currentOperators: [(String, String)] {
        if field == "ip.src" || field == "ip.geoip.asnum" {
            return operatorsForIP
        } else if field == "cf.threat_score" {
            return operatorsForNumber
        }
        return operatorsForString
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                // Rule Details
                Section(header: Text("Rule Details")) {
                    TextField("Rule Name (e.g. Block bad bots)", text: $ruleName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .name)
                    
                    Picker("Editor Mode", selection: $editorMode) {
                        Text("Visual Builder").tag(0)
                        Text("Raw Expression").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 2)
                }
                
                // Quick Presets
                Section(header: Text("Quick Security Presets")) {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            presetButton("Shield WordPress") {
                                ruleName = "Protect WordPress Admin & XML-RPC"
                                field = "http.request.uri.path"
                                operatorType = "contains"
                                value = "/wp-login.php"
                                action = "managed_challenge"
                                rawExpression = "(http.request.uri.path contains \"/wp-login.php\" or http.request.uri.path contains \"/xmlrpc.php\")"
                            }
                            
                            presetButton("Block Malicious Bots") {
                                ruleName = "Block Vulnerability Scanners"
                                field = "http.user_agent"
                                operatorType = "contains"
                                value = "sqlmap"
                                action = "block"
                                rawExpression = "(http.user_agent contains \"sqlmap\" or http.user_agent contains \"nikto\" or http.user_agent contains \"nmap\")"
                            }
                            
                            presetButton("Challenge Foreign Traffic") {
                                ruleName = "Challenge Non-Domestic Visitors"
                                field = "ip.geoip.country"
                                operatorType = "ne"
                                value = "US"
                                action = "managed_challenge"
                                rawExpression = "(ip.geoip.country ne \"US\")"
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .scrollIndicators(.hidden)
                }
                
                if editorMode == 0 {
                    // Visual Builder Section
                    Section(header: Text("When incoming requests match...")) {
                        Picker("Field", selection: $field) {
                            ForEach(fields, id: \.1) { name, val in
                                Text(name).tag(val)
                            }
                        }
                        
                        Picker("Operator", selection: $operatorType) {
                            ForEach(currentOperators, id: \.1) { name, val in
                                Text(name).tag(val)
                            }
                        }
                        .onChange(of: field) { _ in
                            operatorType = currentOperators.first?.1 ?? "eq"
                        }
                        
                        if field == "ip.geoip.country" {
                            TextField("Value (e.g. CN, US, RU)", text: $value)
                                .keyboardType(.asciiCapable)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .value)
                        } else if field == "ip.geoip.asnum" || field == "cf.threat_score" {
                            TextField("Value (e.g. 12345)", text: $value)
                                .keyboardType(.numberPad)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .value)
                        } else if field == "ip.src" {
                            TextField("Value (e.g. 1.1.1.1 or 1.2.3.0/24)", text: $value)
                                .keyboardType(.numbersAndPunctuation)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .value)
                        } else if field == "http.request.method" {
                            Picker("Method", selection: $value) {
                                Text("GET").tag("GET")
                                Text("POST").tag("POST")
                                Text("PUT").tag("PUT")
                                Text("DELETE").tag("DELETE")
                                Text("HEAD").tag("HEAD")
                            }
                        } else {
                            TextField("Value", text: $value)
                                .keyboardType(.asciiCapable)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .value)
                        }
                    }
                } else {
                    // Raw Expression Section
                    Section(header: Text("Wireshark Filter Expression"), footer: Text("Write native Cloudflare Ruleset expressions using Wireshark filter syntax.")) {
                        TextEditor(text: $rawExpression)
                            .frame(minHeight: 100)
                            .font(.system(.body, design: .monospaced))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: .rawExpression)
                    }
                }
                
                Section(header: Text("Then...")) {
                    Picker("Take Action", selection: $action) {
                        ForEach(actions, id: \.1) { name, val in
                            Text(name).tag(val)
                        }
                    }
                }
                
                Section(header: Text("Generated Expression Preview")) {
                    Text(finalEffectiveExpression.isEmpty ? "No expression configured" : finalEffectiveExpression)
                        .font(.footnote.monospaced())
                        .foregroundStyle(finalEffectiveExpression.isEmpty ? .secondary : .primary)
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .centerConstrainedWidth(maxWidth: 840)
            .navigationTitle("New WAF Rule")
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
                    .disabled(ruleName.isEmpty || finalEffectiveExpression.isEmpty || isSubmitting)
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
    
    @ViewBuilder
    // MARK: - Private Views
    private func presetButton(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.impact(.light)
            action()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(CloudnsColor.secondaryGroupedBackground)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.orange.opacity(0.25), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
    
    private var generatedVisualExpression: String {
        guard !value.isEmpty else { return "" }
        
        let needsQuotes = (field != "ip.src" && field != "ip.geoip.asnum" && field != "ip.geoip.country" && field != "cf.threat_score" && operatorType != "in") || field == "http.request.uri.path" || field == "http.user_agent" || field == "http.host" || field == "http.request.method" || field == "http.request.uri.query"
        
        var formattedValue = value
        if field == "ip.geoip.country" || field == "http.request.method" {
            formattedValue = "\"\(value.uppercased())\""
        } else if needsQuotes {
            formattedValue = "\"\(value)\""
        }
        
        return "(\(field) \(operatorType) \(formattedValue))"
    }
    
    private var finalEffectiveExpression: String {
        if editorMode == 1 {
            return rawExpression.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return generatedVisualExpression
        }
    }
    
    // MARK: - Actions
    private func submitRule() async {
        isSubmitting = true
        let expression = finalEffectiveExpression
        
        await viewModel.createRule(
            zoneId: zoneId,
            action: action,
            expression: expression,
            description: ruleName,
            enabled: true
        )
        
        isSubmitting = false
        if viewModel.errorMessage == nil {
            dismiss()
        }
    }
}
