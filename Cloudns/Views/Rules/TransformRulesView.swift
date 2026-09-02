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
            .padding(.horizontal, HIGTokens.Spacing.md)
            .padding(.vertical, HIGTokens.Spacing.sm)
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
                .higTouchTarget(44)
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
                    HIGFeedback.success()
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
                                ToastManager.shared.showSuccess(rule.enabled ? "Rule Disabled" : "Rule Enabled", icon: "slider.horizontal.3")
                            }
                        }
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = rule.expression
                                ToastManager.shared.showCopied("Expression Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy Expression", systemImage: "doc.on.doc")
                            }
                            
                            if let desc = rule.description {
                                Button {
                                    UIPasteboard.general.string = desc
                                    ToastManager.shared.showCopied("Rule Name Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Rule Name", systemImage: "tag")
                                }
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                ruleToDelete = rule
                                showingDeleteAlert = true
                                HIGFeedback.impact(.medium)
                            } label: {
                                Label("Delete Rule", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                ruleToDelete = rule
                                showingDeleteAlert = true
                                HIGFeedback.impact(.medium)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(HIGColors.error)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Transform Rules…"))
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
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.sm) {
            HStack {
                Text(rule.description ?? "Unnamed Rule")
                    .font(HIGTypography.body.weight(.medium))
                Spacer()
                Toggle(isOn: Binding(
                    get: { rule.enabled },
                    set: { _ in onToggle() }
                )) { }
                .labelsHidden()
            }
            
            Text(verbatim: rule.expression)
                .font(HIGTypography.caption2.monospaced())
                .foregroundStyle(.secondary)
                .padding(HIGTokens.Spacing.xs)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.xs, style: .continuous))
                .textSelection(.enabled)
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
}
