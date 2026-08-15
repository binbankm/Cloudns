import SwiftUI

struct RateLimitingRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel = RateLimitingViewModel()
    @State private var showingAddSheet = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            VStack {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding()
                }
                
                if viewModel.isLoading && viewModel.rules.isEmpty {
                    List {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonRowView()
                        }
                    }
                    .listStyle(.insetGrouped)
                } else if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                    EmptyStateView.error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task {
                                await viewModel.fetchRateLimitingRules(zoneId: zoneId)
                            }
                        }
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } else if viewModel.rules.isEmpty && viewModel.hasFetchedData {
                    EmptyStateView(
                        icon: "speedometer",
                        title: "No Rate Limiting Rules",
                        message: "You haven't created any rate limiting rules yet. Add a rule to protect your site from brute force attacks.",
                        actionTitle: "Add Rule",
                        action: { showingAddSheet = true }
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } else {
                    List {
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
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await viewModel.fetchRateLimitingRules(zoneId: zoneId)
                    }
                }
            }
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
