import SwiftUI

struct CacheRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel: CacheRulesViewModel
    @State private var showingAddSheet = false
    
    init(zoneId: String) {
        self.zoneId = zoneId
        _viewModel = StateObject(wrappedValue: CacheRulesViewModel(zoneId: zoneId))
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            VStack {
                if viewModel.isLoading && !viewModel.hasFetchedData {
                    Spacer()
                    ProgressView("Loading Cache Rules...")
                    Spacer()
                } else if viewModel.rules.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "memorychip")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No Cache Rules")
                            .font(.title2.bold())
                        Text("You haven't created any cache rules yet. Create one to customize caching behavior.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.rules) { rule in
                            CacheRuleCardView(rule: rule) {
                                Task {
                                    await viewModel.toggleRule(rule: rule)
                                }
                            }
                        }
                        .onDelete(perform: viewModel.deleteRule)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
        }
        .navigationTitle("Cache Rules")
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
            AddCacheRuleView(zoneId: zoneId, viewModel: viewModel)
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchCacheRules()
            }
        }
        .alert(isPresented: .constant(viewModel.errorMessage != nil)) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK")) {
                    viewModel.errorMessage = nil
                }
            )
        }
    }
}

struct CacheRuleCardView: View {
    let rule: WAFRule
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rule.description ?? "Unnamed Rule")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { rule.enabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }
            
            Text(rule.expression)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(6)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(4)
                .lineLimit(2)
            
            if let cache = rule.action_parameters?.cache {
                HStack {
                    Image(systemName: cache ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(cache ? .green : .red)
                        .font(.caption)
                    Text(cache ? "Eligible for cache" : "Bypass cache")
                        .font(.caption)
                        .foregroundColor(cache ? .green : .red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
