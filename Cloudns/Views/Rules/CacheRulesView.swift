import SwiftUI

// MARK: - CacheRulesView

struct CacheRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel: CacheRulesViewModel
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var ruleToDelete: WAFRule?
    @State private var showingDeleteConfirm = false
    
    init(zoneId: String) {
        self.zoneId = zoneId
        _viewModel = StateObject(wrappedValue: CacheRulesViewModel(zoneId: zoneId))
    }
    
    private var displayedRules: [WAFRule] {
        if searchText.isEmpty { return viewModel.rules }
        return viewModel.rules.filter {
            ($0.description ?? "").localizedStandardContains(searchText) ||
            $0.expression.localizedStandardContains(searchText)
        }
    }
    
    var body: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(WAFRule.placeholders) { placeholderRule in
                        CacheRuleCardView(rule: placeholderRule, onToggle: {})
                    }
                }
                .redacted(reason: .placeholder)
            } else if !displayedRules.isEmpty {
                Section {
                    ForEach(displayedRules) { rule in
                        CacheRuleCardView(rule: rule) {
                            HIGFeedback.selection()
                            Task {
                                await viewModel.toggleRule(rule: rule)
                                ToastManager.shared.showSuccess(rule.enabled ? "Rule Disabled" : "Rule Enabled", icon: "bolt.badge.clock")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                ruleToDelete = rule
                                showingDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search Cache Rules"
        )
        .refreshable {
            await viewModel.fetchCacheRules()
        }
        .navigationTitle("Cache Rules")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchCacheRules() }
                            }
                        )
                    )
                } else if viewModel.rules.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Cache Rules",
                            systemImage: "bolt.badge.clock",
                            description: "You haven't created any custom cache rules yet.",
                            actionTitle: "Add Cache Rule",
                            action: { showingAddSheet = true }
                        )
                    )
                } else if displayedRules.isEmpty && !searchText.isEmpty {
                    HIGContentState(.search(query: searchText))
                }
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(rule.description ?? "Unnamed Rule")
                    .font(.body.weight(.medium))
                Spacer()
                Toggle(isOn: Binding(
                    get: { rule.enabled },
                    set: { _ in onToggle() }
                )) { }
                .labelsHidden()
            }
            
            Text(rule.expression)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .padding(6)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .lineLimit(2)
            
            if let cache = rule.action_parameters?.cache {
                HIGBadge(cache ? .active : .error("Bypass Cache"), isCompact: true)
            }
        }
        .padding(.vertical, 3)
    }
}
