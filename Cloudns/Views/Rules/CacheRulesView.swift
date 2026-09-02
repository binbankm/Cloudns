import SwiftUI

// MARK: - CacheRulesView
// Apple HIG Compliant Cloudflare Cache Rules & Edge TTL Engine

struct CacheRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel: CacheRulesViewModel
    @State private var showingAddSheet = false
    @State private var ruleToDelete: WAFRule?
    @State private var showingDeleteConfirm = false
    
    init(zoneId: String) {
        self.zoneId = zoneId
        _viewModel = StateObject(wrappedValue: CacheRulesViewModel(zoneId: zoneId))
    }
    
    var body: some View {
        List {
            if !viewModel.rules.isEmpty {
                Section(header: Text("Configured Cache Rules (\(viewModel.rules.count))")) {
                    ForEach(viewModel.rules) { rule in
                        CacheRuleCardView(rule: rule) {
                            HIGFeedback.selection()
                            Task {
                                await viewModel.toggleRule(rule: rule)
                                ToastManager.shared.showSuccess(rule.enabled ? "Rule Disabled" : "Rule Enabled", icon: "bolt.badge.clock")
                            }
                        }
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = rule.expression
                                ToastManager.shared.showCopied("Expression Copied")
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
                                ruleToDelete = rule
                                showingDeleteConfirm = true
                                HIGFeedback.impact(.medium)
                            } label: {
                                Label("Delete Rule", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                ruleToDelete = rule
                                showingDeleteConfirm = true
                                HIGFeedback.impact(.medium)
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
            await viewModel.fetchCacheRules()
        }
        .navigationTitle("Cache Rules")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Cache Rules…"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                HIGContentState(
                    .error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task { await viewModel.fetchCacheRules() }
                        }
                    )
                )
            } else if viewModel.hasFetchedData && viewModel.rules.isEmpty {
                HIGContentState(
                    .empty(
                        title: "No Cache Rules",
                        systemImage: "bolt.badge.clock",
                        description: "You haven't created any custom cache rules yet.",
                        actionTitle: "Add Cache Rule",
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
                .accessibilityLabel("Add Cache Rule")
                .higTouchTarget(44)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddCacheRuleView(zoneId: zoneId, viewModel: viewModel)
                .higToast()
        }
        .confirmationDialog(
            "Delete Cache Rule",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            if let rule = ruleToDelete {
                Button("Delete Rule", role: .destructive) {
                    if let index = viewModel.rules.firstIndex(where: { $0.id == rule.id }) {
                        viewModel.deleteRule(at: IndexSet(integer: index))
                        ToastManager.shared.showSuccess("Cache Rule Deleted", icon: "trash.fill")
                        HIGFeedback.success()
                    }
                    ruleToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                ruleToDelete = nil
            }
        } message: {
            if let rule = ruleToDelete {
                Text("Are you sure you want to delete cache rule '\(rule.description ?? "Untitled Rule")'?")
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchCacheRules()
            }
        }
    }
}

// MARK: - CacheRuleCardView (Inlined & Cohesive)

struct CacheRuleCardView: View {
    let rule: WAFRule
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
            HStack {
                Text(rule.description ?? "Unnamed Rule")
                    .font(HIGTypography.body.weight(.medium))
                Spacer()
                Toggle(isOn: Binding(
                    get: { rule.enabled },
                    set: { _ in onToggle() }
                )) { }
                .labelsHidden()
            }
            
            Text(verbatim: rule.expression)
                .font(HIGTypography.caption.monospaced())
                .foregroundStyle(.secondary)
                .padding(HIGTokens.Spacing.xs)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.xs, style: .continuous))
                .lineLimit(2)
            
            if let cache = rule.action_parameters?.cache {
                HIGBadge(cache ? .active : .error("Bypass Cache"), isCompact: true)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
}
