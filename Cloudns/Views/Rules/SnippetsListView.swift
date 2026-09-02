import SwiftUI

// MARK: - SnippetsListView
// Apple HIG Compliant Cloudflare Edge JavaScript Snippets & Phase Rules

struct SnippetsListView: View {
    let zoneId: String
    @StateObject private var viewModel = SnippetsViewModel()
    @State private var showingEditorSheet = false
    @State private var showingBindSheet = false
    @State private var editingSnippet: SnippetItem?
    @State private var snippetToDelete: SnippetItem?
    @State private var ruleToDelete: WAFRule?
    @State private var showingDeleteSnippetAlert = false
    @State private var showingDeleteRuleAlert = false
    
    var body: some View {
        contentView
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edge Snippets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            editingSnippet = nil
                            showingEditorSheet = true
                        } label: {
                            Label("New Snippet Script", systemImage: "curlybraces")
                        }
                        
                        Button {
                            showingBindSheet = true
                        } label: {
                            Label("Add Trigger Rule", systemImage: "arrow.triangle.branch")
                        }
                        .disabled(viewModel.snippets.isEmpty)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Snippet or Trigger Rule")
                    .higTouchTarget(44)
                }
            }
            .sheet(isPresented: $showingEditorSheet) {
                SnippetEditorSheetView(zoneId: zoneId, existingSnippet: editingSnippet, viewModel: viewModel)
                    .higToast()
            }
            .sheet(isPresented: $showingBindSheet) {
                BindSnippetRuleSheetView(zoneId: zoneId, snippets: viewModel.snippets, viewModel: viewModel)
                    .higToast()
            }
            .confirmationDialog("Delete Snippet", isPresented: $showingDeleteSnippetAlert, titleVisibility: .visible, presenting: snippetToDelete) { snip in
                Button("Delete '\(snip.snippet_name)'", role: .destructive) {
                    Task {
                        _ = await viewModel.deleteSnippet(zoneId: zoneId, snippetName: snip.snippet_name)
                        ToastManager.shared.showSuccess("Snippet Deleted", icon: "trash.fill")
                        HIGFeedback.success()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { snip in
                Text("Are you sure you want to delete snippet '\(snip.snippet_name)'?")
            }
            .confirmationDialog("Delete Trigger Rule", isPresented: $showingDeleteRuleAlert, titleVisibility: .visible, presenting: ruleToDelete) { rule in
                Button("Delete '\(rule.description ?? "Rule")'", role: .destructive) {
                    if let rId = viewModel.rulesetId {
                        Task {
                            _ = await viewModel.deleteSnippetRule(zoneId: zoneId, rulesetId: rId, ruleId: rule.id)
                            ToastManager.shared.showSuccess("Trigger Rule Deleted", icon: "trash.fill")
                            HIGFeedback.success()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { rule in
                Text("Are you sure you want to delete trigger rule '\(rule.description ?? rule.id)'?")
            }
            .refreshable {
                await viewModel.fetchSnippets(zoneId: zoneId)
            }
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchSnippets(zoneId: zoneId)
                }
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if !viewModel.snippets.isEmpty {
                Section(header: Text("JavaScript Snippets (\(viewModel.snippets.count))")) {
                    ForEach(viewModel.snippets) { snip in
                        snippetRow(snip)
                    }
                }
            }
            
            if !viewModel.rules.isEmpty {
                Section(header: Text("Trigger Rules (\(viewModel.rules.count))")) {
                    ForEach(viewModel.rules) { rule in
                        ruleRow(rule)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Snippets…"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.snippets.isEmpty && viewModel.rules.isEmpty {
                HIGContentState(
                    .error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task { await viewModel.fetchSnippets(zoneId: zoneId) }
                        }
                    )
                )
            } else if viewModel.hasFetchedData && viewModel.snippets.isEmpty && viewModel.rules.isEmpty {
                HIGContentState(
                    .empty(
                        title: "No Snippets",
                        systemImage: "curlybraces",
                        description: "Run lightweight JavaScript logic on incoming requests directly at the Cloudflare edge.",
                        actionTitle: "Create Snippet",
                        action: {
                            editingSnippet = nil
                            showingEditorSheet = true
                        }
                    )
                )
            }
        }
    }
    
    @ViewBuilder
    private func snippetRow(_ snip: SnippetItem) -> some View {
        Button {
            HIGFeedback.selection()
            editingSnippet = snip
            showingEditorSheet = true
        } label: {
            HStack(spacing: HIGTokens.Spacing.md) {
                ListRowIcon(icon: "curlybraces", color: .orange)

                VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                    Text(verbatim: snip.snippet_name)
                        .font(HIGTypography.body.weight(.medium))
                        .foregroundStyle(.primary)

                    if let modified = snip.modifiedOn, let date = DateFormatters.parseISO8601(modified) {
                        Text("Modified: \(date.displayFormatted(date: .abbreviated, time: .omitted))")
                            .font(HIGTypography.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(HIGTypography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, HIGTokens.Spacing.xxs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                UIPasteboard.general.string = snip.snippet_name
                ToastManager.shared.showCopied("Snippet Name Copied")
                HIGFeedback.copied()
            } label: {
                Label("Copy Snippet Name", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Button(role: .destructive) {
                HIGFeedback.impact(.medium)
                snippetToDelete = snip
                showingDeleteSnippetAlert = true
            } label: {
                Label("Delete Snippet", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                HIGFeedback.impact(.medium)
                snippetToDelete = snip
                showingDeleteSnippetAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(HIGColors.error)
        }
    }
    
    @ViewBuilder
    private func ruleRow(_ rule: WAFRule) -> some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
            HStack {
                Text(rule.description ?? "Snippet Trigger Rule")
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)

                Spacer()

                let isEnabled = rule.enabled
                HIGBadge(isEnabled ? .active : .custom(color: .secondary, text: "Disabled"), isCompact: true)
            }
            
            if let snipName = rule.action_parameters?.snippet_name {
                HStack(spacing: HIGTokens.Spacing.xs) {
                    Image(systemName: "curlybraces")
                        .font(HIGTypography.caption2)
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)
                    Text("Snippet: \(snipName)")
                        .font(HIGTypography.caption.weight(.medium))
                        .foregroundStyle(.orange)
                }
            }
            
            Text(verbatim: rule.expression)
                .font(HIGTypography.caption2.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
        .contextMenu {
            if let desc = rule.description {
                Button {
                    UIPasteboard.general.string = desc
                    ToastManager.shared.showCopied("Rule Description Copied")
                    HIGFeedback.copied()
                } label: {
                    Label("Copy Description", systemImage: "doc.on.doc")
                }
            }
            
            Button {
                UIPasteboard.general.string = rule.expression
                ToastManager.shared.showCopied("Expression Copied")
                HIGFeedback.copied()
            } label: {
                Label("Copy Expression", systemImage: "curlybraces")
            }
            
            Divider()
            
            Button(role: .destructive) {
                HIGFeedback.impact(.medium)
                ruleToDelete = rule
                showingDeleteRuleAlert = true
            } label: {
                Label("Delete Trigger Rule", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                HIGFeedback.impact(.medium)
                ruleToDelete = rule
                showingDeleteRuleAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(HIGColors.error)
        }
    }
}

// MARK: - SnippetEditorSheetView (Inlined & Cohesive)

struct SnippetEditorSheetView: View {
    let zoneId: String
    let existingSnippet: SnippetItem?
    @ObservedObject var viewModel: SnippetsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var snippetName = ""
    @State private var code = """
    export default {
      async fetch(request) {
        // Modify request or response on the edge
        return fetch(request);
      }
    };
    """
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        Image(systemName: "info.circle.fill")
                            .font(HIGTypography.subheadline)
                            .foregroundStyle(.orange)
                        Text("Cloudflare Snippets is available on Pro, Business, and Enterprise plans.")
                            .font(HIGTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, HIGTokens.Spacing.xxs)
                }
                
                Section(header: Text("Snippet Name"), footer: Text("Allowed characters: letters, numbers, and underscores.")) {
                    TextField("my_snippet", text: $snippetName)
                        .font(HIGTypography.body.monospaced())
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .disabled(existingSnippet != nil)
                }
                
                Section(header: Text("JavaScript Code (ES Module)")) {
                    TextEditor(text: $code)
                        .font(HIGTypography.footnote.monospaced())
                        .frame(minHeight: 180)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(verbatim: err)
                            .font(HIGTypography.caption)
                            .foregroundStyle(HIGColors.error)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(existingSnippet?.snippet_name ?? "New Snippet")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .higTouchTarget(44)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            let success = await viewModel.saveSnippet(
                                zoneId: zoneId,
                                name: snippetName,
                                code: code
                            )
                            if success {
                                HIGFeedback.success()
                                ToastManager.shared.showSuccess("Snippet Saved", icon: "curlybraces")
                                dismiss()
                            } else {
                                HIGFeedback.error()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(snippetName.trimmingCharacters(in: .whitespaces).isEmpty || code.isEmpty || isSaving)
                    .higTouchTarget(44)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .task {
                if let ex = existingSnippet {
                    snippetName = ex.snippet_name
                    if let fetched = await viewModel.loadSnippetContent(zoneId: zoneId, name: ex.snippet_name), !fetched.isEmpty {
                        code = fetched
                    }
                }
            }
        }
    }
}

// MARK: - BindSnippetRuleSheetView (Inlined & Cohesive)

struct BindSnippetRuleSheetView: View {
    let zoneId: String
    let snippets: [SnippetItem]
    @ObservedObject var viewModel: SnippetsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSnippetName = ""
    @State private var ruleDescription = ""
    @State private var expression = "http.request.uri.path starts_with \"/api\""
    @State private var isBinding = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Target Snippet")) {
                    Picker("Select Snippet", selection: $selectedSnippetName) {
                        ForEach(snippets) { snip in
                            Text(verbatim: snip.snippet_name).tag(snip.snippet_name)
                        }
                    }
                }
                
                Section(header: Text("Rule Description")) {
                    TextField("e.g. Route /api requests to snippet", text: $ruleDescription)
                        .font(HIGTypography.body)
                        .submitLabel(.next)
                }
                
                Section(header: Text("Matching Expression"), footer: Text("Requests matching this wirefilter expression will execute the selected snippet.")) {
                    TextField("Expression", text: $expression)
                        .font(HIGTypography.footnote.monospaced())
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(verbatim: err)
                            .font(HIGTypography.caption)
                            .foregroundStyle(HIGColors.error)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Trigger Rule")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .higTouchTarget(44)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bind") {
                        Task {
                            isBinding = true
                            errorMessage = nil
                            let success = await viewModel.bindSnippetRule(
                                zoneId: zoneId,
                                snippetName: selectedSnippetName,
                                expression: expression,
                                description: ruleDescription.isEmpty ? nil : ruleDescription
                            )
                            if success {
                                HIGFeedback.success()
                                ToastManager.shared.showSuccess("Trigger Rule Created", icon: "arrow.triangle.branch")
                                dismiss()
                            } else {
                                HIGFeedback.error()
                            }
                            isBinding = false
                        }
                    }
                    .disabled(selectedSnippetName.isEmpty || expression.trimmingCharacters(in: .whitespaces).isEmpty || isBinding)
                    .higTouchTarget(44)
                }
            }
            .interactiveDismissDisabled(isBinding)
            .onAppear {
                if selectedSnippetName.isEmpty, let first = snippets.first {
                    selectedSnippetName = first.snippet_name
                }
            }
        }
    }
}
