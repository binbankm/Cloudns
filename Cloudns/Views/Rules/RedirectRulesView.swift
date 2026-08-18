import SwiftUI

struct RedirectRulesView: View {
    let zoneId: String
    @StateObject private var viewModel = RedirectRulesViewModel()
    @State private var showingAddSheet = false
    @State private var ruleToDelete: RedirectRuleItem?
    @State private var showingDeleteAlert = false
    @State private var searchText = ""
    
    private var displayedRules: [RedirectRuleItem] {
        if searchText.isEmpty { return viewModel.rules }
        return viewModel.rules.filter {
            ($0.description ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.expression ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.targetUrl ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        contentView
            .navigationTitle("Redirect Rules")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Redirect Rules")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
                Button("Delete '\(rule.description ?? "Rule")'", role: .destructive) {
                    Task {
                        await viewModel.deleteRule(zoneId: zoneId, ruleId: rule.id, description: rule.description)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { rule in
                Text("Are you sure you want to delete redirect rule '\(rule.description ?? "Rule")'?")
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
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section(header: Text("Configured Rules")) {
                    ForEach(RedirectRuleItem.placeholders) { placeholderRule in
                        redirectRuleRow(placeholderRule)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
            } else if !displayedRules.isEmpty {
                Section(header: Text("Configured Rules (\(displayedRules.count))")) {
                    ForEach(displayedRules) { rule in
                        redirectRuleRow(rule)
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
                            icon: "arrow.triangle.swap",
                            title: "No Redirect Rules",
                            message: "Configure URL forwarding and dynamic 301/302 redirects at the Cloudflare edge.",
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
    }
    
    @ViewBuilder
    private func redirectRuleRow(_ rule: RedirectRuleItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rule.description ?? "Untitled Rule")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                let isEnabled = rule.enabled ?? true
                CloudnsBadge(isEnabled ? .active("Active") : .custom(color: .secondary, text: "Disabled"), isCompact: true)
            }
            
            HStack(spacing: 6) {
                if let status = rule.statusCode {
                    CloudnsBadge(.custom(color: .blue, text: "\(status)"), isCompact: true)
                }
                
                if let url = rule.targetUrl {
                    Text("➔ \(url)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
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
        .padding(.vertical, 4)
    }
}

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
                Section(header: Text("Rule Description")) {
                    TextField("Rule Name", text: $ruleDescription)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                }
                
                Section(header: Text("Matching Expression"), footer: Text("Cloudflare wirefilter expression defining which incoming requests trigger redirection.")) {
                    TextField("Expression", text: $expression)
                        .font(.footnote.monospaced())
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                }
                
                Section(header: Text("Redirect Target & Code")) {
                    TextField("Target URL (e.g. https://example.com/new)", text: $targetUrl)
                        .font(.footnote)
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
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Redirect Rule")
            .navigationBarTitleDisplayMode(.inline)
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
                                dismiss()
                            }
                            isCreating = false
                        }
                    }
                    .disabled(ruleDescription.trimmingCharacters(in: .whitespaces).isEmpty || expression.trimmingCharacters(in: .whitespaces).isEmpty || targetUrl.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
            .toastContainer()
        }
    }
}
