import SwiftUI

struct RateLimitingRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel = RateLimitingViewModel()
    @State private var showingAddSheet = false
    @State private var ruleToDelete: WAFRule?
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        List {
            if !viewModel.rules.isEmpty {
                Section {
                    ForEach(viewModel.rules) { rule in
                        WAFRuleCardView(rule: rule, onToggle: {
                            HIGFeedback.selection()
                            Task {
                                await viewModel.toggleRule(zoneId: zoneId, rule: rule)
                                ToastManager.shared.showSuccess(rule.enabled ? "Rule Disabled" : "Rule Enabled", icon: "speedometer")
                            }
                        })
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
        .refreshable {
            await viewModel.fetchRateLimitingRules(zoneId: zoneId)
        }
        .navigationTitle("Rate Limiting")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Rate Limiting Rules..."))
            } else if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                HIGContentState(
                    .error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task { await viewModel.fetchRateLimitingRules(zoneId: zoneId) }
                        }
                    )
                )
            } else if viewModel.hasFetchedData && viewModel.rules.isEmpty {
                HIGContentState(
                    .empty(
                        title: "No Rate Limiting Rules",
                        systemImage: "speedometer",
                        description: "You haven't created any rate limiting rules yet. Add a rule to protect your site from brute force attacks.",
                        actionTitle: "Add Rule",
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
                .accessibilityLabel("Add Rate Limiting Rule")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddRateLimitingRuleView(zoneId: zoneId, viewModel: viewModel)
             .higToast()
        }
        .confirmationDialog(
            "Delete Rate Limiting Rule",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            if let rule = ruleToDelete {
                Button("Delete Rule", role: .destructive) {
                    Task {
                        await viewModel.deleteRule(zoneId: zoneId, ruleId: rule.id)
                        ToastManager.shared.showSuccess("Rate Limiting Rule Deleted", icon: "trash.fill")
                        ruleToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                ruleToDelete = nil
            }
        } message: {
            if let rule = ruleToDelete {
                Text("Are you sure you want to delete rate limiting rule '\(rule.description ?? "Untitled Rule")'?")
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchRateLimitingRules(zoneId: zoneId)
            }
        }
    }
}
