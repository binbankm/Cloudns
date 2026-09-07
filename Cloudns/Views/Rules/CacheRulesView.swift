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
                            HapticManager.selection()
                            Task {
                                await viewModel.toggleRule(rule: rule)
                                ToastManager.shared.showSuccess(rule.enabled ? LocalizedStringKey("Rule Disabled") : LocalizedStringKey("Rule Enabled"), icon: "bolt.badge.clock")
                            }
                        }
                        .contextMenu {
                            Button {
                                copyToClipboard(rule.expression, toast: "Expression Copied")
                            } label: {
                                Label("Copy Expression", systemImage: "doc.on.doc")
                            }
                            
                            if let desc = rule.description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Button {
                                    copyToClipboard(desc, toast: "Rule Name Copied")
                                } label: {
                                    Label("Copy Rule Name", systemImage: "tag")
                                }
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                ruleToDelete = rule
                                showingDeleteConfirm = true
                                HapticManager.impact(.medium)
                            } label: {
                                Label("Delete Rule", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                ruleToDelete = rule
                                showingDeleteConfirm = true
                                HapticManager.impact(.medium)
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
            await viewModel.fetchCacheRules()
        }
        .navigationTitle("Cache Rules")
        .navigationBarTitleDisplayMode(.inline)
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Cache Rules…",
            error: viewModel.rules.isEmpty ? viewModel.errorMessage : nil,
            isEmpty: viewModel.hasFetchedData && viewModel.rules.isEmpty,
            empty: EmptyStateConfig(
                title: "No Cache Rules",
                systemImage: "bolt.badge.clock",
                description: "You haven't created any custom cache rules yet.",
                actionTitle: "Add Cache Rule",
                action: { showingAddSheet = true }
            ),
            onRetry: { Task { await viewModel.fetchCacheRules() } }
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showingAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Cache Rule")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddCacheRuleView(zoneId: zoneId, viewModel: viewModel)
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
                        HapticManager.notification(.success)
                    }
                    ruleToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                ruleToDelete = nil
            }
        } message: {
            if let rule = ruleToDelete {
                let ruleName = (rule.description?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s } ?? String(localized: "Untitled Rule")
                Text("Are you sure you want to delete cache rule '\(ruleName)'?")
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
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let desc = rule.description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(desc)
                        .font(.body.weight(.medium))
                } else {
                    Text("Unnamed Rule")
                        .font(.body.weight(.medium))
                }
                Spacer()
                Toggle(isOn: Binding(
                    get: { rule.enabled },
                    set: { _ in onToggle() }
                )) { }
                .labelsHidden()
            }
            
            Text(verbatim: rule.expression)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .padding(4)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .lineLimit(2)
            
            if let cache = rule.action_parameters?.cache {
                Text(cache ? LocalizedStringKey("Active") : LocalizedStringKey("Bypass Cache"))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(cache ? Color.green : Color.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(cache ? Color.green.opacity(0.12) : Color.orange.opacity(0.12)))
            }
        }
        .padding(.vertical, 2)
    }
}
