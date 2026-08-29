import SwiftUI

// MARK: - CacheRulesView

struct CacheRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel: CacheRulesViewModel
    @State private var showingAddSheet = false
    @State private var searchText = ""
    
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
                            }
                        }
                    }
                    .onDelete(perform: { indexSet in
                        HIGFeedback.impact(.medium)
                        for index in indexSet {
                            viewModel.deleteRule(at: IndexSet(integer: index))
                        }
                    })
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
