import SwiftUI

struct RateLimitingRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel = RateLimitingViewModel()
    @State private var showingAddSheet = false
    
    var body: some View {
        List {
            if viewModel.isLoading && viewModel.rules.isEmpty {
                Section {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                Section {
                    EmptyStateView.error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task {
                                await viewModel.fetchRateLimitingRules(zoneId: zoneId)
                            }
                        }
                    )
                }
                .listRowBackground(Color.clear)
            } else if viewModel.rules.isEmpty && viewModel.hasFetchedData {
                Section {
                    EmptyStateView(
                        icon: "speedometer",
                        title: "No Rate Limiting Rules",
                        message: "You haven't created any rate limiting rules yet. Add a rule to protect your site from brute force attacks.",
                        actionTitle: "Add Rule",
                        action: { showingAddSheet = true }
                    )
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(viewModel.rules) { rule in
                        WAFRuleCardView(rule: rule, onToggle: {
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
                .accessibilityLabel("添加速率限制规则")
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
        .refreshable {
            await viewModel.fetchRateLimitingRules(zoneId: zoneId)
        }
    }
    
    private func deleteRules(at offsets: IndexSet) {
        for index in offsets {
            let rule = viewModel.rules[index]
            Task {
                await viewModel.deleteRule(zoneId: zoneId, ruleId: rule.id)
                ToastManager.shared.showSuccess("Rate Limiting Rule Deleted", message: rule.description ?? "")
            }
        }
    }
}
