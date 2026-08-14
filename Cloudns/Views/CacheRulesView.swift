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
                if viewModel.isLoading && viewModel.rules.isEmpty {
                    List {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonRowView()
                        }
                    }
                    .listStyle(.insetGrouped)
                } else {
                    List {
                        if viewModel.rules.isEmpty {
                            EmptyStateView(
                                icon: "bolt.badge.clock",
                                title: "No Cache Rules",
                                message: "You haven't created any custom cache rules yet.",
                                actionTitle: "Add Cache Rule",
                                action: { showingAddSheet = true }
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(viewModel.rules) { rule in
                                CacheRuleCardView(rule: rule) {
                                    Task {
                                        await viewModel.toggleRule(rule: rule)
                                    }
                                }
                            }
                            .onDelete(perform: { indexSet in
                                for index in indexSet {
                                    let rule = viewModel.rules[index]
                                    viewModel.deleteRule(at: IndexSet(integer: index))
                                    ToastManager.shared.showSuccess("Cache Rule Deleted", message: rule.description ?? "")
                                }
                            })
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .refreshable {
                        await viewModel.fetchCacheRules()
                    }
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
