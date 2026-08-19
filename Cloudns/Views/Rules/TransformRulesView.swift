import SwiftUI

struct TransformRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel: TransformRulesViewModel
    @State private var showingAddSheet = false
    @State private var ruleToDelete: WAFRule?
    @State private var showingDeleteAlert = false
    @State private var searchText = ""
    
    init(zoneId: String) {
        self.zoneId = zoneId
        _viewModel = StateObject(wrappedValue: TransformRulesViewModel(zoneId: zoneId))
    }
    
    private var displayedRules: [WAFRule] {
        if searchText.isEmpty { return viewModel.rules }
        return viewModel.rules.filter {
            ($0.description ?? "").localizedCaseInsensitiveContains(searchText) ||
            $0.expression.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            Section {
                Picker("Phase", selection: $viewModel.selectedPhase) {
                    Text("URL Rewrite").tag("http_request_transform")
                    Text("Request Headers").tag("http_request_late_transform")
                    Text("Response Headers").tag("http_response_headers_transform")
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section(header: Text("\(phaseTitle(for: viewModel.selectedPhase)) Rules")) {
                    ForEach(WAFRule.placeholders) { placeholderRule in
                        TransformRuleCardView(rule: placeholderRule, onToggle: {})
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
            } else if !displayedRules.isEmpty {
                Section(header: Text("\(phaseTitle(for: viewModel.selectedPhase)) Rules (\(displayedRules.count))")) {
                    ForEach(displayedRules) { rule in
                        TransformRuleCardView(rule: rule) {
                            HapticManager.impact(.light)
                            Task {
                                await viewModel.toggleRule(rule: rule)
                                ToastManager.shared.showSuccess("Rule Status Updated", message: rule.description ?? "Rule")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                ruleToDelete = rule
                                showingDeleteAlert = true
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
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Transform Rules")
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchTransformRules() }
                            }
                        )
                    )
                } else if viewModel.rules.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "arrow.triangle.2.circlepath",
                            title: "No \(phaseTitle(for: viewModel.selectedPhase)) Rules",
                            message: "Configure URL rewrites and request/response header transformations at the edge.",
                            actionTitle: "Add Rule",
                            action: { showingAddSheet = true }
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
        .refreshable {
            await viewModel.fetchTransformRules()
        }
        .navigationTitle("Transform Rules")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Transform Rule")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTransformRuleView(zoneId: zoneId, initialPhase: viewModel.selectedPhase, viewModel: viewModel)
        }
        .confirmationDialog("Delete Transform Rule", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: ruleToDelete) { rule in
            Button("Delete '\(rule.description ?? "Rule")'", role: .destructive) {
                Task {
                    await viewModel.deleteRule(ruleId: rule.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { rule in
            Text("Are you sure you want to delete '\(rule.description ?? "Rule")'?")
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchTransformRules()
            }
        }
    }
    
    private func phaseTitle(for phase: String) -> String {
        switch phase {
        case "http_request_transform": return "URL Rewrite"
        case "http_request_late_transform": return "Request Header"
        case "http_response_headers_transform": return "Response Header"
        default: return "Transform"
        }
    }
}
