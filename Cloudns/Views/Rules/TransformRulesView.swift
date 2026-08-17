import SwiftUI

struct TransformRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel: TransformRulesViewModel
    @State private var showingAddSheet = false
    @State private var ruleToDelete: WAFRule? = nil
    @State private var showingDeleteAlert = false
    
    init(zoneId: String) {
        self.zoneId = zoneId
        _viewModel = StateObject(wrappedValue: TransformRulesViewModel(zoneId: zoneId))
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

            if !viewModel.hasFetchedData {
                Section {
                    ForEach(WAFRule.placeholders) { rule in
                        TransformRuleCardView(rule: rule, onToggle: {})
                            .skeletonLoading(true)
                    }
                }
            } else if !viewModel.rules.isEmpty {
                Section(header: Text("\(phaseTitle(for: viewModel.selectedPhase)) Rules (\(viewModel.rules.count))")) {
                    ForEach(viewModel.rules) { rule in
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
        .animation(.easeInOut(duration: 0.25), value: viewModel.hasFetchedData)
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

struct TransformRuleCardView: View {
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
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .padding(6)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 4))
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
                            .foregroundStyle(.blue)
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
                            .foregroundStyle(.indigo)
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
