import SwiftUI

// MARK: - AddGatewayRuleSheetView

struct AddGatewayRuleSheetView: View {
    @ObservedObject var viewModel: GatewayRulesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var ruleName: String = ""
    @State private var ruleAction: String = "block"
    @State private var filterType: String = "dns"
    @State private var trafficExpression: String = "dns.security.category in {1 2}"
    @State private var isEnabled: Bool = true
    
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    
    private let availableActions: [(id: String, name: String, color: Color)] = [
        ("block", "Block", .red),
        ("allow", "Allow", .green),
        ("isolate", "Isolate", .purple),
        ("off", "Disabled (Off)", .secondary)
    ]
    
    private let availableFilters: [(id: String, name: String)] = [
        ("dns", "DNS Filtering"),
        ("http", "HTTP / Web Traffic"),
        ("l4", "Network Layer 4")
    ]
    
    private let expressionTemplates: [(name: String, filter: String, action: String, expr: String)] = [
        ("Block Malware & Phishing", "dns", "block", "dns.security.category in {1 2}"),
        ("Block Adult / NSFW Sites", "dns", "block", "dns.content.category in {67 125}"),
        ("Isolate Social Media", "http", "isolate", "http.request.host in {\"facebook.com\" \"x.com\" \"instagram.com\"}"),
        ("Block High Risk TLDs", "dns", "block", "dns.fqdn in {\".zip\" \".mov\" \".xyz\"}")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 1. Basic Rule Information
                Section(header: Text("Rule Information")) {
                    TextField("Rule Name (e.g. Block Malware)", text: $ruleName)
                        .keyboardType(.default)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    
                    Picker("Action", selection: $ruleAction) {
                        ForEach(availableActions, id: \.id) { act in
                            HStack {
                                Circle()
                                    .fill(act.color)
                                    .frame(width: 8, height: 8)
                                Text(act.name)
                            }
                            .tag(act.id)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Rule Scope", selection: $filterType) {
                        ForEach(availableFilters, id: \.id) { f in
                            Text(f.name).tag(f.id)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Toggle("Enable Rule", isOn: $isEnabled)
                }
                
                // MARK: - 2. Quick Templates
                Section(header: Text("Expression Templates")) {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(expressionTemplates, id: \.name) { t in
                                Button {
                                    HapticManager.selection()
                                    ruleName = t.name
                                    filterType = t.filter
                                    ruleAction = t.action
                                    trafficExpression = t.expr
                                } label: {
                                    Text(t.name)
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color(.separator), lineWidth: 0.8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .scrollIndicators(.hidden)
                }
                
                // MARK: - 3. Traffic Expression
                Section(
                    header: Text("Traffic Expression"),
                    footer: Text("Cloudflare Rules expression determining which queries or requests trigger this action.")
                ) {
                    TextEditor(text: $trafficExpression)
                        .font(.body.monospaced())
                        .frame(minHeight: 80)
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
            .navigationTitle("Add Gateway Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveRule() }
                    }
                    .disabled(!isValid || isSaving)
                    .overlay {
                        if isSaving { ProgressView() }
                    }
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
    
    private var isValid: Bool {
        !ruleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !trafficExpression.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveRule() async {
        let cleanName = ruleName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTraffic = trafficExpression.trimmingCharacters(in: .whitespacesAndNewlines)
        
        isSaving = true
        errorMessage = nil
        HapticManager.impact(.medium)
        
        do {
            try await viewModel.createRule(
                name: cleanName,
                action: ruleAction,
                traffic: cleanTraffic,
                enabled: isEnabled,
                filters: [filterType]
            )
            HapticManager.notification(.success)
            CloudnsToastManager.shared.showSuccess("Gateway Rule Created", message: cleanName)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
