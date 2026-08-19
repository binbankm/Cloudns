import SwiftUI

struct IPAccessRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel = IPAccessRulesViewModel()
    @State private var showingAddRule = false
    @State private var searchText = ""
    
    private var displayedRules: [IPAccessRule] {
        if searchText.isEmpty { return viewModel.rules }
        return viewModel.rules.filter {
            $0.configuration.value.localizedCaseInsensitiveContains(searchText) ||
            $0.configuration.target.localizedCaseInsensitiveContains(searchText) ||
            $0.mode.localizedCaseInsensitiveContains(searchText) ||
            ($0.notes ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(IPAccessRule.placeholders) { placeholderRule in
                        IPAccessRuleRowView(rule: placeholderRule)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
            } else if !displayedRules.isEmpty {
                Section {
                    ForEach(displayedRules) { rule in
                        IPAccessRuleRowView(rule: rule)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    Task {
                                        await viewModel.deleteRule(zoneId: zoneId, ruleId: rule.id)
                                        ToastManager.shared.showSuccess("IP Rule Deleted", message: rule.configuration.value)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search IP Rules")
        .refreshable {
            await viewModel.fetchRules(zoneId: zoneId)
        }
        .navigationTitle("IP Access Rules")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchRules(zoneId: zoneId) }
                            }
                        )
                    )
                } else if viewModel.rules.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "network.badge.shield.half.filled",
                            title: "No IP Access Rules",
                            message: "You haven't created any IP access rules yet. Add a rule to block or challenge specific IPs or countries.",
                            actionTitle: "Add IP Rule",
                            action: { showingAddRule = true }
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddRule = true
                }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add IP Rule")
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchRules(zoneId: zoneId)
            }
        }
        .sheet(isPresented: $showingAddRule) {
            AddIPAccessRuleView(zoneId: zoneId, viewModel: viewModel, isPresented: $showingAddRule)
        }
    }
}
