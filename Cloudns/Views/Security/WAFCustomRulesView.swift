import SwiftUI

struct WAFCustomRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel = WAFViewModel()
    @State private var showingAddSheet = false
    @State private var searchText = ""
    
    private var displayedRules: [WAFRule] {
        if searchText.isEmpty { return viewModel.rules }
        return viewModel.rules.filter {
            ($0.description ?? "").localizedCaseInsensitiveContains(searchText) ||
            $0.expression.localizedCaseInsensitiveContains(searchText) ||
            $0.action.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(WAFRule.placeholders) { placeholderRule in
                        WAFRuleCardView(rule: placeholderRule, onToggle: {})
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
            } else if !displayedRules.isEmpty {
                Section {
                    ForEach(displayedRules) { rule in
                        WAFRuleCardView(rule: rule, onToggle: {
                            HapticManager.impact(.light)
                            Task {
                                await viewModel.toggleRule(zoneId: zoneId, rule: rule)
                                ToastManager.shared.showSuccess("WAF Rule Updated", message: "\(rule.description ?? "Rule") status updated")
                            }
                        })
                    }
                    .onDelete(perform: deleteRules)
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search WAF Rules")
        .refreshable {
            await viewModel.fetchWAFRules(zoneId: zoneId)
        }
        .navigationTitle("WAF Custom Rules")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchWAFRules(zoneId: zoneId) }
                            }
                        )
                    )
                } else if viewModel.rules.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "shield.checkerboard",
                            title: "No WAF Rules",
                            message: "You haven't created any custom WAF rules yet. Add a rule to inspect incoming traffic.",
                            actionTitle: "Add WAF Rule",
                            action: { showingAddSheet = true }
                        )
                    )
                } else if displayedRules.isEmpty && !searchText.isEmpty {
                    StateOverlayView(
                        state: .search(
                            query: searchText,
                            clearAction: { searchText = "" }
                        )
                    )
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add WAF Rule")
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
    }
    
    private func deleteRules(at offsets: IndexSet) {
        HapticManager.impact(.medium)
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
                CloudnsBadge(.custom(color: colorForAction(rule.action), text: actionDisplayName(rule.action)), isCompact: true)
                
                Spacer()
                
                CloudnsBadge(rule.enabled ? .active("Active") : .custom(color: .secondary, text: "Disabled"), isCompact: true)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Expression")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(rule.expression)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.primary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
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
