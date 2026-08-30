import SwiftUI

// MARK: - TransformRulesView

struct TransformRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel: TransformRulesViewModel
    @State private var showingAddSheet = false
    @State private var ruleToDelete: WAFRule?
    @State private var showingDeleteAlert = false
    
    init(zoneId: String) {
        self.zoneId = zoneId
        _viewModel = StateObject(wrappedValue: TransformRulesViewModel(zoneId: zoneId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Phase", selection: $viewModel.selectedPhase) {
                Text("Rewrite URL").tag("http_request_transform")
                Text("Request Headers").tag("http_request_late_transform")
                Text("Response Headers").tag("http_response_headers_transform")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            
            contentList
        }
        .background(Color(.systemGroupedBackground))
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
             .higToast()
        }
        .confirmationDialog("Delete Transform Rule", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: ruleToDelete) { rule in
            Button("Delete '\(rule.description ?? "Rule")'", role: .destructive) {
                Task {
                    await viewModel.deleteRule(ruleId: rule.id)
                    ToastManager.shared.showSuccess("Transform Rule Deleted", icon: "trash.fill")
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
    private var contentList: some View {
        List {
            if !viewModel.rules.isEmpty {
                Section(header: HStack {
                    Text("\(phaseTitle(for: viewModel.selectedPhase)) Rules (\(viewModel.rules.count))")
                    Spacer()
                    HIGBadge(viewModel.selectedPhase == "http_response_headers_transform" ? .warning("PRO") : .custom(color: .secondary, text: "FREE"), isCompact: true)
                }) {
                    ForEach(viewModel.rules) { rule in
                        TransformRuleCardView(rule: rule) {
                            HIGFeedback.selection()
                            Task {
                                await viewModel.toggleRule(rule: rule)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
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
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Transform Rules..."))
            } else if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                HIGContentState(
                    .error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task { await viewModel.fetchTransformRules() }
                        }
                    )
                )
            } else if viewModel.hasFetchedData && viewModel.rules.isEmpty {
                HIGContentState(
                    .empty(
                        title: "No Transform Rules",
                        systemImage: "arrow.triangle.swap",
                        description: "Rewrite URL paths, query strings, or modify HTTP headers dynamically at the edge.",
                        actionTitle: "Add Rule",
                        action: { showingAddSheet = true }
                    )
                )
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

// MARK: - TransformRuleCardView (Inlined & Cohesive)

struct TransformRuleCardView: View {
    let rule: WAFRule
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rule.description ?? "Unnamed Rule")
                    .font(.body.weight(.medium))
                Spacer()
                Toggle(isOn: Binding(
                    get: { rule.enabled },
                    set: { _ in onToggle() }
                )) { }
                .labelsHidden()
            }
            
            Text(rule.expression)
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .padding(6)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .lineLimit(2)
            
            if let uri = rule.action_parameters?.uri {
                if let path = uri.path?.value {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .foregroundStyle(.blue)
                            .font(.caption2)
                            .accessibilityHidden(true)
                        Text("Rewrite Path -> \(path)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if let query = uri.query?.value {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.indigo)
                            .font(.caption2)
                            .accessibilityHidden(true)
                        Text("Rewrite Query -> \(query)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if let headers = rule.action_parameters?.headers {
                ForEach(Array(headers.keys), id: \.self) { headerKey in
                    if let item = headers[headerKey] {
                        HStack(spacing: 4) {
                            Image(systemName: item.operation == "remove" ? "minus.circle.fill" : "plus.circle.fill")
                                .foregroundStyle(item.operation == "remove" ? .red : .green)
                                .font(.caption2)
                                .accessibilityHidden(true)
                            Text("\(item.operation.capitalized) '\(headerKey)': \(item.value ?? "(removed)")")
                                .font(.caption)
                                .foregroundStyle(item.operation == "remove" ? .red : .primary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
