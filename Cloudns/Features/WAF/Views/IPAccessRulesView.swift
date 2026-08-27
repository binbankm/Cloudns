import SwiftUI

struct IPAccessRulesView: View {
    // MARK: - Properties
    let zoneId: String
    
    @StateObject private var viewModel = IPAccessRulesViewModel()
    @State private var showingAddRule = false
    @State private var searchText = ""
    
    private var displayedRules: [IPAccessRule] {
        if searchText.isEmpty { return viewModel.rules }
        return viewModel.rules.filter {
            $0.configuration.value.localizedStandardContains(searchText) ||
            $0.configuration.target.localizedStandardContains(searchText) ||
            $0.mode.localizedStandardContains(searchText) ||
            ($0.notes ?? "").localizedStandardContains(searchText)
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $searchText,
                prompt: "Search IP Rules"
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(Color(.systemGroupedBackground))
            
            List {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section {
                        ForEach(IPAccessRule.placeholders) { placeholderRule in
                            IPAccessRuleRowView(rule: placeholderRule)
                        }
                    }
                    .skeletonLoading(true)
                } else if !displayedRules.isEmpty {
                    Section {
                        ForEach(displayedRules) { rule in
                            IPAccessRuleRowView(rule: rule)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        HapticManager.impact(.medium)
                                        Task {
                                            await viewModel.deleteRule(zoneId: zoneId, ruleId: rule.id)
                                            CloudnsToastManager.shared.showSuccess("IP Rule Deleted", message: rule.configuration.value)
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
            .scrollDismissesKeyboard(.interactively)
            .centerConstrainedWidth(maxWidth: 840)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            await viewModel.fetchRules(zoneId: zoneId)
        }
        .navigationTitle("IP Access Rules")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                    CloudnsStateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchRules(zoneId: zoneId) }
                            }
                        )
                    )
                } else if viewModel.rules.isEmpty {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "network.badge.shield.half.filled",
                            title: "No IP Access Rules",
                            message: "You haven't created any IP access rules yet. Add a rule to block or challenge specific IPs or countries.",
                            actionTitle: "Add IP Rule",
                            action: { showingAddRule = true }
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
