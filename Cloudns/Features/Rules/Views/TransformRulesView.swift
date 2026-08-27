import SwiftUI

struct TransformRulesView: View {
    // MARK: - Properties
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
            ($0.description ?? "").localizedStandardContains(searchText) ||
            $0.expression.localizedStandardContains(searchText)
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $searchText,
                prompt: "Search Transform Rules"
            )
            .padding(.horizontal, CloudnsSpacing.md)
            .padding(.top, CloudnsSpacing.sm)
            .padding(.bottom, CloudnsSpacing.xs)
            .background(CloudnsColor.groupedBackground)
            
            Picker("Phase", selection: $viewModel.selectedPhase) {
                Text("Rewrite URL").tag("http_request_transform")
                Text("Request Headers").tag("http_request_late_transform")
                Text("Response Headers").tag("http_response_headers_transform")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, CloudnsSpacing.sm)
            .background(CloudnsColor.groupedBackground)
            
            contentList
                .centerConstrainedWidth(maxWidth: 840)
        }
        .background(CloudnsColor.groupedBackground)
        .navigationTitle("Transform Rules")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchTransformRules()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
    
    @ViewBuilder
    // MARK: - Private Views
    private var contentList: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(WAFRule.placeholders) { placeholderRule in
                        TransformRuleCardView(rule: placeholderRule, onToggle: {})
                    }
                }
                .skeletonLoading(true)
            } else if !displayedRules.isEmpty {
                Section(header: HStack {
                    Text("\(phaseTitle(for: viewModel.selectedPhase)) Rules (\(displayedRules.count))")
                    Spacer()
                    CloudnsBadge(viewModel.selectedPhase == "http_response_headers_transform" ? .pro : .free, isCompact: true)
                }) {
                    ForEach(displayedRules) { rule in
                        TransformRuleCardView(rule: rule) {
                            HapticManager.impact(.light)
                            Task {
                                await viewModel.toggleRule(rule: rule)
                                CloudnsToastManager.shared.showSuccess("Rule Status Updated", message: rule.description ?? "Rule")
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
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                    CloudnsStateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchTransformRules() }
                            }
                        )
                    )
                } else if viewModel.rules.isEmpty {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "arrow.triangle.2.circlepath",
                            title: "No \(phaseTitle(for: viewModel.selectedPhase)) Rules",
                            message: "Configure URL rewrites and request/response header transformations at the edge.",
                            actionTitle: "Add Rule",
                            action: { showingAddSheet = true }
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
    }
    
    // MARK: - Actions
    private func phaseTitle(for phase: String) -> String {
        switch phase {
        case "http_request_transform": return "URL Rewrite"
        case "http_request_late_transform": return "Request Header"
        case "http_response_headers_transform": return "Response Header"
        default: return "Transform"
        }
    }
}
