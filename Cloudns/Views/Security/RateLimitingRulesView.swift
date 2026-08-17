import SwiftUI

struct RateLimitingRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel = RateLimitingViewModel()
    @State private var showingAddSheet = false
    
    var body: some View {
        List {
            if !viewModel.rules.isEmpty {
                Section {
                    ForEach(viewModel.rules) { rule in
                        WAFRuleCardView(rule: rule, onToggle: {
                            HapticManager.impact(.light)
                            Task {
                                await viewModel.toggleRule(zoneId: zoneId, rule: rule)
                                ToastManager.shared.showSuccess("Rate Limiting Rule Updated", message: "\(rule.description ?? "Rule") status updated")
                            }
                        })
                    }
                    .onDelete(perform: deleteRules)
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchRateLimitingRules(zoneId: zoneId) }
                            }
                        )
                    )
                } else if viewModel.rules.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "speedometer",
                            title: "No Rate Limiting Rules",
                            message: "You haven't created any rate limiting rules yet. Add a rule to protect your site from brute force attacks.",
                            actionTitle: "Add Rule",
                            action: { showingAddSheet = true }
                        )
                    )
                }
            }
        }
        .refreshable {
            await viewModel.fetchRateLimitingRules(zoneId: zoneId)
        }
        .navigationTitle("Rate Limiting")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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
    
    private func deleteRules(at offsets: IndexSet) {
        HapticManager.impact(.medium)
        for index in offsets {
            let rule = viewModel.rules[index]
            Task {
                await viewModel.deleteRule(zoneId: zoneId, ruleId: rule.id)
                ToastManager.shared.showSuccess("Rate Limiting Rule Deleted", message: rule.description ?? "")
            }
        }
    }
}
