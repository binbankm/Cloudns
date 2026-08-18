import SwiftUI

struct AddWAFRuleView: View {
    let zoneId: String
    @ObservedObject var viewModel: WAFViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var ruleName = ""
    @State private var action = "block"
    
    @State private var field = "ip.src"
    @State private var operatorType = "eq"
    @State private var value = ""
    
    @State private var isSubmitting = false
    @FocusState private var focusedField: FocusableField?
    
    enum FocusableField {
        case name
        case value
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
        ("ASN", "ip.geoip.asnum"),
        ("URI Path", "http.request.uri.path"),
        ("User Agent", "http.user_agent"),
        ("Hostname", "http.host")
    ]
    
    let operatorsForString = [
        ("Equals", "eq"),
        ("Does not equal", "ne"),
        ("Contains", "contains"),
        ("Does not contain", "not contains")
    ]
    
    let operatorsForIP = [
        ("Equals", "eq"),
        ("Does not equal", "ne"),
        ("In list", "in")
    ]
    
    var currentOperators: [(String, String)] {
        if field == "ip.src" || field == "ip.geoip.asnum" {
            return operatorsForIP
        }
        return operatorsForString
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Rule Details")) {
                    TextField("Rule Name (e.g. Block bad bots)", text: $ruleName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .value }
                }
                
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
                            .submitLabel(.done)
                            .focused($focusedField, equals: .value)
                    } else if field == "ip.geoip.asnum" {
                        TextField("Value (e.g. 12345)", text: $value)
                            .keyboardType(.numberPad)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .focused($focusedField, equals: .value)
                    } else if field == "ip.src" {
                        TextField("Value (e.g. 1.1.1.1 or 1.2.3.0/24)", text: $value)
                            .keyboardType(.numbersAndPunctuation)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .focused($focusedField, equals: .value)
                    } else {
                        TextField("Value", text: $value)
                            .keyboardType(.asciiCapable)
                            .submitLabel(.done)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .value)
                    }
                }
                
                Section(header: Text("Then...")) {
                    Picker("Take Action", selection: $action) {
                        ForEach(actions, id: \.1) { name, val in
                            Text(name).tag(val)
                        }
                    }
                }
                
                Section(header: Text("Generated Expression")) {
                    Text(generatedExpression)
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
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
                    .disabled(ruleName.isEmpty || value.isEmpty || isSubmitting)
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
    
    private var generatedExpression: String {
        guard !value.isEmpty else { return "" }
        
        let needsQuotes = (field != "ip.src" && field != "ip.geoip.asnum" && field != "ip.geoip.country" && operatorType != "in") || field == "http.request.uri.path" || field == "http.user_agent" || field == "http.host"
        
        var formattedValue = value
        if field == "ip.geoip.country" {
            formattedValue = "\"\(value.uppercased())\""
        } else if needsQuotes {
            formattedValue = "\"\(value)\""
        }
        
        return "(\(field) \(operatorType) \(formattedValue))"
    }
    
    private func submitRule() async {
        isSubmitting = true
        let expression = generatedExpression
        
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
