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

            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else if viewModel.rules.isEmpty && viewModel.hasFetchedData {
                Section {
                    EmptyStateView(
                        icon: "arrow.triangle.2.circlepath",
                        title: "No \(phaseTitle(for: viewModel.selectedPhase)) Rules",
                        message: "Configure URL rewrites and request/response header transformations at the edge.",
                        actionTitle: "Add Rule",
                        action: { showingAddSheet = true }
                    )
                }
                .listRowBackground(Color.clear)
            } else {
                Section(header: Text("\(phaseTitle(for: viewModel.selectedPhase)) Rules (\(viewModel.rules.count))")) {
                    ForEach(viewModel.rules) { rule in
                        TransformRuleCardView(rule: rule) {
                            Task {
                                await viewModel.toggleRule(rule: rule)
                                ToastManager.shared.showSuccess("Rule Status Updated", message: rule.description ?? "Rule")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
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
                .accessibilityLabel("添加转换规则")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTransformRuleView(zoneId: zoneId, initialPhase: viewModel.selectedPhase, viewModel: viewModel)
        }
        .alert("Delete Transform Rule", isPresented: $showingDeleteAlert, presenting: ruleToDelete) { rule in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteRule(ruleId: rule.id)
                }
            }
        } message: { rule in
            Text("Are you sure you want to delete '\(rule.description ?? "Rule")'?")
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchTransformRules()
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        ), actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        })
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
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(4)
                .lineLimit(2)
            
            if let uri = rule.action_parameters?.uri {
                if let path = uri.path?.value {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .foregroundStyle(.blue)
                            .font(.caption2)
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
