import SwiftUI

// MARK: - RedirectRulesView
// Apple HIG Compliant Cloudflare Redirect Rules (301/302/307/308 Edge URL Forwarding)

struct RedirectRulesView: View {
    let zoneId: String
    @StateObject private var viewModel = RedirectRulesViewModel()
    @State private var showingAddSheet = false
    @State private var ruleToDelete: RedirectRuleItem?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        contentView
            .navigationTitle("Redirect Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Redirect Rule")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddRedirectRuleSheetView(zoneId: zoneId, viewModel: viewModel)
            }
            .confirmationDialog("Delete Redirect Rule", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: ruleToDelete) { rule in
                let ruleName = (rule.description?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s } ?? String(localized: "Untitled Rule")
                Button("Delete '\(ruleName)'", role: .destructive) {
                    Task {
                        _ = await viewModel.deleteRule(zoneId: zoneId, ruleId: rule.id, description: rule.description)
                        ToastManager.shared.showSuccess("Redirect Rule Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { rule in
                let ruleName = (rule.description?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s } ?? String(localized: "Untitled Rule")
                Text("Are you sure you want to delete redirect rule '\(ruleName)'?")
            }
            .refreshable {
                await viewModel.fetchRules(zoneId: zoneId)
            }
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchRules(zoneId: zoneId)
                }
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if !viewModel.rules.isEmpty {
                Section("Configured Rules (\(viewModel.rules.count))") {
                    ForEach(viewModel.rules) { rule in
                        redirectRuleRow(rule)
                            .contextMenu {
                                if let url = rule.targetUrl {
                                    Button {
                                        copyToClipboard(url, toast: "Target URL Copied")
                                    } label: {
                                        Label("Copy Target URL", systemImage: "doc.on.doc")
                                    }
                                }
                                
                                if let expr = rule.expression {
                                    Button {
                                        copyToClipboard(expr, toast: "Expression Copied")
                                    } label: {
                                        Label("Copy Expression", systemImage: "curlybraces")
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
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Redirect Rules…",
            error: viewModel.rules.isEmpty ? viewModel.errorMessage : nil,
            isEmpty: viewModel.hasFetchedData && viewModel.rules.isEmpty,
            empty: EmptyStateConfig(
                title: "No Redirect Rules",
                systemImage: "arrow.triangle.swap",
                description: "Configure URL forwarding and dynamic 301/302 redirects at the Cloudflare edge.",
                actionTitle: "Add Rule",
                action: { showingAddSheet = true }
            ),
            onRetry: {
                Task { await viewModel.fetchRules(zoneId: zoneId) }
            }
        )
    }
    
    @ViewBuilder
    private func redirectRuleRow(_ rule: RedirectRuleItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let desc = rule.description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(desc)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                } else {
                    Text("Untitled Rule")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                let isEnabled = rule.enabled ?? true
                Text(isEnabled ? LocalizedStringKey("Active") : LocalizedStringKey("Disabled"))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isEnabled ? Color.green : Color.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill((isEnabled ? Color.green : Color.secondary).opacity(0.12)))
            }
            
            HStack(spacing: 6) {
                if let status = rule.statusCode {
                    Text("\(status)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.blue.opacity(0.12)))
                }
                
                if let url = rule.targetUrl {
                    Text("➔ \(url)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.tint)
                        .lineLimit(1)
                }
            }
            
            if let expr = rule.expression {
                Text(expr)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - AddRedirectRuleSheetView (Inlined & Cohesive)

struct AddRedirectRuleSheetView: View {
    let zoneId: String
    @ObservedObject var viewModel: RedirectRulesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var ruleDescription = ""
    @State private var expression = "http.request.uri.path eq \"/old-path\""
    @State private var targetUrl = "https://example.com/new-path"
    @State private var statusCode = 301
    @State private var preserveQueryString = false
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Rule Description") {
                    TextField("Rule Name", text: $ruleDescription)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                }
                
                Section {
                    TextField("Expression", text: $expression)
                        .font(.footnote.monospaced())
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                } header: {
                    Text("Matching Expression")
                } footer: {
                    Text("Cloudflare wirefilter expression defining which incoming requests trigger redirection.")
                }
                
                Section("Redirect Target & Code") {
                    TextField("Target URL (e.g. https://example.com/new)", text: $targetUrl)
                        .font(.footnote.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                    
                    Picker("Status Code", selection: $statusCode) {
                        Text("301 - Moved Permanently").tag(301)
                        Text("302 - Found (Temporary)").tag(302)
                        Text("307 - Temporary Redirect").tag(307)
                        Text("308 - Permanent Redirect").tag(308)
                    }
                    
                    Toggle("Preserve Query String", isOn: $preserveQueryString)
                }
                
                if let err = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(verbatim: err)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Redirect Rule")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            errorMessage = nil
                            let success = await viewModel.createRule(
                                zoneId: zoneId,
                                description: ruleDescription,
                                expression: expression,
                                targetUrl: targetUrl,
                                statusCode: statusCode,
                                preserveQueryString: preserveQueryString
                            )
                            if success {
                                ToastManager.shared.showSuccess("Redirect Rule Created", icon: "arrow.turn.up.right")
                                HapticManager.notification(.success)
                                dismiss()
                            } else {
                                ToastManager.shared.showError("Failed to Create Rule")
                                HapticManager.notification(.error)
                            }
                            isCreating = false
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(ruleDescription.trimmingCharacters(in: .whitespaces).isEmpty || expression.trimmingCharacters(in: .whitespaces).isEmpty || targetUrl.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}
