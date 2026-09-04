import SwiftUI

// MARK: - WAFCustomRulesView
// Apple HIG Compliant Cloudflare Web Application Firewall Custom Rule Engine

struct WAFCustomRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel = WAFViewModel()
    @State private var showingAddSheet = false
    @State private var ruleToDelete: WAFRule?
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        List {
            if !viewModel.rules.isEmpty {
                Section(header: Text("Custom Rules (\(viewModel.rules.count))")) {
                    ForEach(viewModel.rules) { rule in
                        WAFRuleCardView(rule: rule, onToggle: {
                            HapticManager.selection()
                            Task {
                                await viewModel.toggleRule(zoneId: zoneId, rule: rule)
                                ToastManager.shared.showSuccess(rule.enabled ? "WAF Rule Disabled" : "WAF Rule Enabled", icon: "shield.lefthalf.filled")
                            }
                        })
                        .contextMenu {
                            Button {
                                copyToClipboard(rule.expression, toast: "Rule Expression Copied")
                            } label: {
                                Label("Copy Expression", systemImage: "doc.on.doc")
                            }
                            
                            if let desc = rule.description {
                                Button {
                                    copyToClipboard(desc, toast: "Rule Name Copied")
                                } label: {
                                    Label("Copy Rule Name", systemImage: "tag")
                                }
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                ruleToDelete = rule
                                showingDeleteConfirm = true
                            } label: {
                                Label("Delete Rule", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                ruleToDelete = rule
                                showingDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.fetchWAFRules(zoneId: zoneId)
        }
        .navigationTitle("WAF Custom Rules")
        .navigationBarTitleDisplayMode(.inline)
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading WAF Rules…",
            error: viewModel.rules.isEmpty ? viewModel.errorMessage : nil,
            isEmpty: viewModel.hasFetchedData && viewModel.rules.isEmpty,
            empty: EmptyStateConfig(
                title: "No WAF Custom Rules",
                systemImage: "shield.slash",
                description: "Create custom firewall rules to protect your web application from malicious traffic.",
                actionTitle: "Add WAF Rule",
                action: { showingAddSheet = true }
            ),
            onRetry: { Task { await viewModel.fetchWAFRules(zoneId: zoneId) } }
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
                .higToast()
        }
        .confirmationDialog(
            "Delete WAF Rule",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            if let rule = ruleToDelete {
                Button("Delete Rule", role: .destructive) {
                    Task {
                        await viewModel.deleteRule(zoneId: zoneId, ruleId: rule.id)
                        ToastManager.shared.showSuccess("WAF Rule Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                        ruleToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                ruleToDelete = nil
            }
        } message: {
            if let rule = ruleToDelete {
                Text("Are you sure you want to delete WAF rule '\(rule.description ?? "Untitled Rule")'?")
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchWAFRules(zoneId: zoneId)
            }
        }
    }
}

// MARK: - WAFRuleCardView

struct WAFRuleCardView: View {
    let rule: WAFRule
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rule.description ?? "Untitled Rule")
                    .font(.body.weight(.medium))
                    .lineLimit(2)
                
                Spacer()
                
                Toggle(isOn: Binding(
                    get: { rule.enabled },
                    set: { _ in onToggle() }
                )) { }
                .labelsHidden()
            }
            
            HStack {
                let actionColor = colorForAction(rule.action)
                Text(actionDisplayName(rule.action))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(actionColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(actionColor.opacity(0.12)))
                
                Spacer()
                
                Text(rule.enabled ? "Active" : "Disabled")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(rule.enabled ? Color.accentColor : Color.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(rule.enabled ? Color.accentColor.opacity(0.12) : Color(.tertiarySystemFill)))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Expression")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text(verbatim: rule.expression)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.primary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func actionDisplayName(_ action: String) -> String {
        switch action.lowercased() {
        case "block": return "Block"
        case "managed_challenge": return "Managed Challenge"
        case "js_challenge": return "JS Challenge"
        case "challenge": return "Interactive Challenge"
        case "log": return "Log"
        case "skip": return "Skip"
        default: return action.capitalized
        }
    }
    
    private func colorForAction(_ action: String) -> Color {
        switch action.lowercased() {
        case "block": return .red
        case "managed_challenge", "js_challenge", "challenge": return .orange
        case "log": return .blue
        case "skip": return .green
        default: return .secondary
        }
    }
}
