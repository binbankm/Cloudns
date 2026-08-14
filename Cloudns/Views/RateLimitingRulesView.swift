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
                
                if viewModel.isLoading && !viewModel.hasFetchedData {
                    Spacer()
                    ProgressView("Loading Rate Limiting Rules...")
                    Spacer()
                } else if viewModel.rules.isEmpty && viewModel.hasFetchedData {
                    Spacer()
                    EmptyStateView(
                        icon: "speedometer",
                        title: "No Rate Limiting Rules",
                        message: "You haven't created any rate limiting rules yet. Protect your site from CC attacks by setting threshold rules."
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.rules) { rule in
                            WAFRuleCardView(rule: rule, onToggle: {
                                Task {
                                    await viewModel.toggleRule(zoneId: zoneId, rule: rule)
                                }
                            })
                        }
                        .onDelete(perform: deleteRules)
                    }
                    .listStyle(InsetGroupedListStyle())
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
            }
        }
    }
}
