import SwiftUI

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
                            HapticManager.impact(.light)
                            Task {
                                await viewModel.toggleRule(rule: rule)
                            }
                        }
                    }
                    .onDelete(perform: { indexSet in
                        HapticManager.impact(.medium)
                        for index in indexSet {
                            let rule = displayedRules[index]
                            viewModel.deleteRule(at: IndexSet(integer: index))
                            ToastManager.shared.showSuccess("Cache Rule Deleted", message: rule.description ?? "")
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
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchCacheRules() }
                            }
                        )
                    )
                } else if viewModel.rules.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "bolt.badge.clock",
                            title: "No Cache Rules",
                            message: "You haven't created any custom cache rules yet.",
                            actionTitle: "Add Cache Rule",
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
