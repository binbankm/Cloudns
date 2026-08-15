import SwiftUI

struct WAFCustomRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel = WAFViewModel()
    @State private var showingAddSheet = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)

            if viewModel.isLoading && viewModel.rules.isEmpty {
                List {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
                .listStyle(.insetGrouped)
            } else if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                EmptyStateView.error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task {
                            await viewModel.fetchWAFRules(zoneId: zoneId)
                        }
                    }
                )
            } else if viewModel.rules.isEmpty && viewModel.hasFetchedData {
                EmptyStateView(
                    icon: "shield.checkerboard",
                    title: "No WAF Rules",
                    message: "You haven't created any custom WAF rules yet. Add a rule to inspect incoming traffic.",
                    actionTitle: "Add WAF Rule",
                    action: { showingAddSheet = true }
                )
            } else {
                List {
                    ForEach(viewModel.rules) { rule in
                        WAFRuleCardView(rule: rule, onToggle: {
                            Task {
                                await viewModel.toggleRule(zoneId: zoneId, rule: rule)
                                ToastManager.shared.showSuccess("WAF Rule Updated", message: "\(rule.description ?? "Rule") status updated")
                            }
                        })
                    }
                    .onDelete(perform: deleteRules)
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.fetchWAFRules(zoneId: zoneId)
                }
            }
        }
        .navigationTitle("WAF Custom Rules")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddWAFRuleView(zoneId: zoneId, viewModel: viewModel)
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchWAFRules(zoneId: zoneId)
            }
        }
        .refreshable {
            await viewModel.fetchWAFRules(zoneId: zoneId)
        }
    }
    
    private func deleteRules(at offsets: IndexSet) {
        for index in offsets {
            let rule = viewModel.rules[index]
            Task {
                await viewModel.deleteRule(zoneId: zoneId, ruleId: rule.id)
                ToastManager.shared.showSuccess("WAF Rule Deleted", message: rule.description ?? "")
            }
        }
    }
}

struct WAFRuleCardView: View {
    let rule: WAFRule
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(rule.description ?? "Untitled Rule")
                    .font(.body)
                    .lineLimit(2)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { rule.enabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }
            
            HStack {
                Text(actionDisplayName(rule.action))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorForAction(rule.action).opacity(0.1))
                    .foregroundColor(colorForAction(rule.action))
                    .cornerRadius(6)
                
                Spacer()
                
                Text(rule.enabled ? "Active" : "Disabled")
                    .font(.caption)
                    .foregroundColor(rule.enabled ? .green : .secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Expression")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(rule.expression)
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(6)
                    // Allows user to long press and copy the expression
                    .textSelection(.enabled) 
            }
        }
        .padding(.vertical, 8)
    }
    
    private func actionDisplayName(_ action: String) -> String {
        switch action {
        case "block": return "BLOCK"
        case "challenge": return "LEGACY CAPTCHA"
        case "js_challenge": return "JS CHALLENGE"
        case "managed_challenge": return "MANAGED CHALLENGE"
        case "log": return "LOG"
        case "skip": return "SKIP"
        default: return action.uppercased()
        }
    }
    
    private func colorForAction(_ action: String) -> Color {
        switch action {
        case "block": return .red
        case "challenge", "js_challenge", "managed_challenge": return .orange
        case "log": return .blue
        case "skip": return .green
        default: return .gray
        }
    }
}
