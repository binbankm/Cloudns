import SwiftUI

// MARK: - TransformRulesView
// Apple HIG Compliant Cloudflare Transform Rules (URL Rewrite & Header Manipulation)

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
            .padding(.horizontal, 16)
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
        }
        .confirmationDialog("Delete Transform Rule", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: ruleToDelete) { rule in
            Button("Delete '\(rule.description ?? "Rule")'", role: .destructive) {
                Task {
                    await viewModel.deleteRule(ruleId: rule.id)
                    ToastManager.shared.showSuccess("Transform Rule Deleted", icon: "trash.fill")
                    HapticManager.notification(.success)
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
                    let isPro = viewModel.selectedPhase == "http_response_headers_transform"
                    Text(isPro ? "PRO" : "FREE")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isPro ? Color.orange.opacity(0.14) : Color(.tertiarySystemFill))
                        .foregroundStyle(isPro ? Color.orange : Color.secondary)
                        .clipShape(Capsule())
                }) {
                    ForEach(viewModel.rules) { rule in
                        TransformRuleCardView(rule: rule) {
                            HapticManager.selection()
                            Task {
                                await viewModel.toggleRule(rule: rule)
                                ToastManager.shared.showSuccess(rule.enabled ? "Rule Disabled" : "Rule Enabled", icon: "slider.horizontal.3")
                            }
                        }
                        .contextMenu {
                            Button {
                                copyToClipboard(rule.expression, toast: "Expression Copied")
                            } label: {
                                Label("Copy Expression", systemImage: "doc.on.doc")
                            }
                            
                            if let desc = rule.description {
                                Button {
                                    copyToClipboard(desc, toast: "Rule Name Copied")
                                } label: {
                                    Label("Copy Rule Name", systemImage: "tag")
                                }
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                ruleToDelete = rule
                                showingDeleteAlert = true
                                HapticManager.impact(.medium)
                            } label: {
                                Label("Delete Rule", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                ruleToDelete = rule
                                showingDeleteAlert = true
                                HapticManager.impact(.medium)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Transform Rules…",
            error: viewModel.rules.isEmpty ? viewModel.errorMessage : nil,
            isEmpty: viewModel.hasFetchedData && viewModel.rules.isEmpty,
            empty: EmptyStateConfig(
                title: "No Transform Rules",
                systemImage: "arrow.triangle.swap",
                description: "Rewrite URL paths, query strings, or modify HTTP headers dynamically at the edge.",
                actionTitle: "Add Rule",
                action: { showingAddSheet = true }
            ),
            onRetry: { Task { await viewModel.fetchTransformRules() } }
        )
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
            
            Text(verbatim: rule.expression)
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .padding(4)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }
}
