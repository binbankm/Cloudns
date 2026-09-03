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
                            HIGFeedback.selection()
                            Task {
                                await viewModel.toggleRule(zoneId: zoneId, rule: rule)
                                ToastManager.shared.showSuccess(rule.enabled ? "WAF Rule Disabled" : "WAF Rule Enabled", icon: "shield.lefthalf.filled")
                            }
                        })
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = rule.expression
                                ToastManager.shared.showCopied("Rule Expression Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy Expression", systemImage: "doc.on.doc")
                            }
                            
                            if let desc = rule.description {
                                Button {
                                    UIPasteboard.general.string = desc
                                    ToastManager.shared.showCopied("Rule Name Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Rule Name", systemImage: "tag")
                                }
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                ruleToDelete = rule
                                showingDeleteConfirm = true
                            } label: {
                                Label("Delete Rule", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                ruleToDelete = rule
                                showingDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(HIGColors.error)
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
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading WAF Rules…"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                HIGContentState(
                    .error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task { await viewModel.fetchWAFRules(zoneId: zoneId) }
                        }
                    )
                )
            } else if viewModel.hasFetchedData && viewModel.rules.isEmpty {
                HIGContentState(
                    .empty(
                        title: "No WAF Custom Rules",
                        systemImage: "shield.slash",
                        description: "Create custom firewall rules to protect your web application from malicious traffic.",
                        actionTitle: "Add WAF Rule",
                        action: { showingAddSheet = true }
                    )
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showingAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add WAF Rule")
                .higTouchTarget(44)
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
                        HIGFeedback.success()
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

// MARK: - WAFRuleCardView (Inlined & Cohesive)

struct WAFRuleCardView: View {
    let rule: WAFRule
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.sm) {
            HStack {
                Text(rule.description ?? "Untitled Rule")
                    .font(HIGTypography.body.weight(.medium))
                    .lineLimit(2)
                
                Spacer()
                
                Toggle(isOn: Binding(
                    get: { rule.enabled },
                    set: { _ in onToggle() }
                )) { }
                .labelsHidden()
            }
            
            HStack {
                HIGBadge(.custom(color: colorForAction(rule.action), text: actionDisplayName(rule.action)), isCompact: true)
                
                Spacer()
                
                HIGBadge(rule.enabled ? .active : .custom(color: .secondary, text: "Disabled"), isCompact: true)
            }
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text("Expression")
                    .font(HIGTypography.caption2)
                    .foregroundStyle(.secondary)
                
                Text(verbatim: rule.expression)
                    .font(HIGTypography.footnote.monospaced())
                    .foregroundStyle(.primary)
                    .padding(HIGTokens.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.sm, style: .continuous))
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
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
        case "block": return HIGColors.error
        case "managed_challenge", "js_challenge", "challenge": return .orange
        case "log": return .blue
        case "skip": return HIGColors.success
        default: return .secondary
        }
    }
}
