import SwiftUI

struct RateLimitingRulesView: View {
    // MARK: - Properties
    let zoneId: String
    
    @StateObject private var viewModel = RateLimitingViewModel()
    @State private var showingAddSheet = false
    @State private var searchText = ""
    
    private var displayedRules: [WAFRule] {
        if searchText.isEmpty { return viewModel.rules }
        return viewModel.rules.filter {
            ($0.description ?? "").localizedStandardContains(searchText) ||
            $0.expression.localizedStandardContains(searchText) ||
            $0.action.localizedStandardContains(searchText)
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $searchText,
                prompt: "Search Rate Limiting Rules"
            )
            .padding(.horizontal, CloudnsSpacing.md)
            .padding(.top, CloudnsSpacing.sm)
            .padding(.bottom, CloudnsSpacing.xs)
            .background(CloudnsColor.groupedBackground)
            
            List {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section {
                        ForEach(WAFRule.placeholders) { placeholderRule in
                            WAFRuleCardView(rule: placeholderRule, onToggle: {})
                        }
                    }
                    .skeletonLoading(true)
                } else if !displayedRules.isEmpty {
                    Section {
                        ForEach(displayedRules) { rule in
                            WAFRuleCardView(rule: rule, onToggle: {
                                HapticManager.impact(.light)
                                Task {
                                    await viewModel.toggleRule(zoneId: zoneId, rule: rule)
                                    CloudnsToastManager.shared.showSuccess("Rate Limiting Rule Updated", message: "\(rule.description ?? "Rule") status updated")
                                }
                            })
                        }
                        .onDelete(perform: deleteRules)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .centerConstrainedWidth(maxWidth: 840)
        }
        .background(CloudnsColor.groupedBackground)
        .refreshable {
            await viewModel.fetchRateLimitingRules(zoneId: zoneId)
        }
        .navigationTitle("Rate Limiting")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                    CloudnsStateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchRateLimitingRules(zoneId: zoneId) }
                            }
                        )
                    )
                } else if viewModel.rules.isEmpty {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "speedometer",
                            title: "No Rate Limiting Rules",
                            message: "You haven't created any rate limiting rules yet. Add a rule to protect your site from brute force attacks.",
                            actionTitle: "Add Rule",
                            action: { showingAddSheet = true }
                        )
                    )
                } else if displayedRules.isEmpty && !searchText.isEmpty {
                    CloudnsStateOverlayView(
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
                .accessibilityLabel("Add Rate Limiting Rule")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddRateLimitingRuleView(zoneId: zoneId, viewModel: viewModel)
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchRateLimitingRules(zoneId: zoneId)
            }
        }
    }
    
    // MARK: - Actions
    private func deleteRules(at offsets: IndexSet) {
        HapticManager.impact(.medium)
        for index in offsets {
            let rule = viewModel.rules[index]
            Task {
                await viewModel.deleteRule(zoneId: zoneId, ruleId: rule.id)
                CloudnsToastManager.shared.showSuccess("Rate Limiting Rule Deleted", message: rule.description ?? "")
            }
        }
    }
}
