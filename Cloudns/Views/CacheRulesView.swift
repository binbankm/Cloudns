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
        List {
            if !viewModel.hasFetchedData {
                Section {
                    ForEach(WAFRule.placeholders) { rule in
                        CacheRuleCardView(rule: rule, onToggle: {})
                    }
                }
                .skeletonLoading(true)
            } else if !viewModel.rules.isEmpty {
                Section {
                    ForEach(viewModel.rules) { rule in
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
                            let rule = viewModel.rules[index]
                            viewModel.deleteRule(at: IndexSet(integer: index))
                            ToastManager.shared.showSuccess("Cache Rule Deleted", message: rule.description ?? "")
                        }
                    })
                }
            }
        }
        .listStyle(.insetGrouped)
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
                }
            }
        }
        .refreshable {
            await viewModel.fetchCacheRules()
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

struct CacheRuleCardView: View {
    let rule: WAFRule
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rule.description ?? "Unnamed Rule")
                    .font(.body)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { rule.enabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }
            
            Text(rule.expression)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .padding(6)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .lineLimit(2)
            
            if let cache = rule.action_parameters?.cache {
                HStack {
                    Image(systemName: cache ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(cache ? .green : .red)
                        .font(.caption)
                        .accessibilityHidden(true)
                    Text(cache ? "Eligible for cache" : "Bypass cache")
                        .font(.caption)
                        .foregroundStyle(cache ? .green : .red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
