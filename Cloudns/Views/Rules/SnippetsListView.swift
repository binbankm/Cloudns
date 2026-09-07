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
            .navigationTitle("Edge Snippets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
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
                }
            }
            .sheet(isPresented: $showingEditorSheet) {
                SnippetEditorSheetView(zoneId: zoneId, existingSnippet: editingSnippet, viewModel: viewModel)
            }
            .sheet(isPresented: $showingBindSheet) {
                BindSnippetRuleSheetView(zoneId: zoneId, snippets: viewModel.snippets, viewModel: viewModel)
            }
            .confirmationDialog("Delete Snippet", isPresented: $showingDeleteSnippetAlert, titleVisibility: .visible, presenting: snippetToDelete) { snip in
                Button("Delete '\(snip.snippet_name)'", role: .destructive) {
                    Task {
                        _ = await viewModel.deleteSnippet(zoneId: zoneId, snippetName: snip.snippet_name)
                        ToastManager.shared.showSuccess("Snippet Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { snip in
                Text("Are you sure you want to delete snippet '\(snip.snippet_name)'?")
            }
            .confirmationDialog("Delete Trigger Rule", isPresented: $showingDeleteRuleAlert, titleVisibility: .visible, presenting: ruleToDelete) { rule in
                let ruleName = (rule.description?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s } ?? String(localized: "Rule")
                Button("Delete '\(ruleName)'", role: .destructive) {
                    if let rId = viewModel.rulesetId {
                        Task {
                            _ = await viewModel.deleteSnippetRule(zoneId: zoneId, rulesetId: rId, ruleId: rule.id)
                            ToastManager.shared.showSuccess("Trigger Rule Deleted", icon: "trash.fill")
                            HapticManager.notification(.success)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { rule in
                let ruleName = (rule.description?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s } ?? rule.id
                Text("Are you sure you want to delete trigger rule '\(ruleName)'?")
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
                Section("JavaScript Snippets (\(viewModel.snippets.count))") {
                    ForEach(viewModel.snippets) { snip in
                        snippetRow(snip)
                    }
                }
            }
            
            if !viewModel.rules.isEmpty {
                Section("Trigger Rules (\(viewModel.rules.count))") {
                    ForEach(viewModel.rules) { rule in
                        ruleRow(rule)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Snippets…",
            error: (viewModel.snippets.isEmpty && viewModel.rules.isEmpty) ? viewModel.errorMessage : nil,
            isEmpty: viewModel.hasFetchedData && viewModel.snippets.isEmpty && viewModel.rules.isEmpty,
            empty: EmptyStateConfig(
                title: "No Snippets",
                systemImage: "curlybraces",
                description: "Run lightweight JavaScript logic on incoming requests directly at the Cloudflare edge.",
                actionTitle: "Create Snippet",
                action: {
                    editingSnippet = nil
                    showingEditorSheet = true
                }
            ),
            onRetry: {
                Task { await viewModel.fetchSnippets(zoneId: zoneId) }
            }
        )
    }
    
    @ViewBuilder
    private func snippetRow(_ snip: SnippetItem) -> some View {
        Button {
            HapticManager.selection()
            editingSnippet = snip
            showingEditorSheet = true
        } label: {
            HStack(spacing: 12) {
                ListRowIcon(icon: "curlybraces", color: .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: snip.snippet_name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)

                    if let modified = snip.modifiedOn, let date = DateFormatters.parseISO8601(modified) {
                        Text("Modified: \(date.displayFormatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                copyToClipboard(snip.snippet_name, toast: "Snippet Name Copied")
            } label: {
                Label("Copy Snippet Name", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Button(role: .destructive) {
                HapticManager.impact(.medium)
                snippetToDelete = snip
                showingDeleteSnippetAlert = true
            } label: {
                Label("Delete Snippet", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                HapticManager.impact(.medium)
                snippetToDelete = snip
                showingDeleteSnippetAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    @ViewBuilder
    private func ruleRow(_ rule: WAFRule) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let desc = rule.description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(desc)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                } else {
                    Text("Snippet Trigger Rule")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                }

                Spacer()

                let isEnabled = rule.enabled
                Text(isEnabled ? LocalizedStringKey("Active") : LocalizedStringKey("Disabled"))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isEnabled ? Color.green : Color.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill((isEnabled ? Color.green : Color.secondary).opacity(0.12)))
            }
            
            if let snipName = rule.action_parameters?.snippet_name {
                HStack(spacing: 6) {
                    Image(systemName: "curlybraces")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)
                    Text("Snippet: \(snipName)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                }
            }
            
            Text(verbatim: rule.expression)
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
        .contextMenu {
            if let desc = rule.description {
                Button {
                    copyToClipboard(desc, toast: "Rule Description Copied")
                } label: {
                    Label("Copy Description", systemImage: "doc.on.doc")
                }
            }
            
            Button {
                copyToClipboard(rule.expression, toast: "Expression Copied")
            } label: {
                Label("Copy Expression", systemImage: "curlybraces")
            }
            
            Divider()
            
            Button(role: .destructive) {
                HapticManager.impact(.medium)
                ruleToDelete = rule
                showingDeleteRuleAlert = true
            } label: {
                Label("Delete Trigger Rule", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                HapticManager.impact(.medium)
                ruleToDelete = rule
                showingDeleteRuleAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
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
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                        Text("Cloudflare Snippets is available on Pro, Business, and Enterprise plans.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                
                Section(header: Text("Snippet Name"), footer: Text("Allowed characters: letters, numbers, and underscores.")) {
                    TextField("my_snippet", text: $snippetName)
                        .font(.body.monospaced())
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .disabled(existingSnippet != nil)
                }
                
                Section("JavaScript Code (ES Module)") {
                    TextEditor(text: $code)
                        .font(.footnote.monospaced())
                        .frame(minHeight: 180)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(verbatim: err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(existingSnippet?.snippet_name ?? String(localized: "New Snippet"))
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
                                HapticManager.notification(.success)
                                ToastManager.shared.showSuccess("Snippet Saved", icon: "curlybraces")
                                dismiss()
                            } else {
                                HapticManager.notification(.error)
                            }
                            isSaving = false
                        }
                    }
                    .disabled(snippetName.trimmingCharacters(in: .whitespaces).isEmpty || code.isEmpty || isSaving)
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
                Section("Target Snippet") {
                    Picker("Select Snippet", selection: $selectedSnippetName) {
                        ForEach(snippets) { snip in
                            Text(verbatim: snip.snippet_name).tag(snip.snippet_name)
                        }
                    }
                }
                
                Section("Rule Description") {
                    TextField("e.g. Route /api requests to snippet", text: $ruleDescription)
                        .submitLabel(.next)
                }
                
                Section {
                    TextField("Expression", text: $expression)
                        .font(.footnote.monospaced())
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                } header: {
                    Text("Matching Expression")
                } footer: {
                    Text("Requests matching this wirefilter expression will execute the selected snippet.")
                }
                
                if let err = errorMessage {
                    Section {
                        Text(verbatim: err)
                            .font(.caption)
                            .foregroundStyle(.red)
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
                                HapticManager.notification(.success)
                                ToastManager.shared.showSuccess("Trigger Rule Created", icon: "arrow.triangle.branch")
                                dismiss()
                            } else {
                                HapticManager.notification(.error)
                            }
                            isBinding = false
                        }
                    }
                    .disabled(selectedSnippetName.isEmpty || expression.trimmingCharacters(in: .whitespaces).isEmpty || isBinding)
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
