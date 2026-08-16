import SwiftUI

struct SnippetsListView: View {
    let zoneId: String
    @StateObject private var viewModel = SnippetsViewModel()
    @State private var showingEditorSheet = false
    @State private var showingBindSheet = false
    @State private var editingSnippet: SnippetItem? = nil
    @State private var snippetToDelete: SnippetItem? = nil
    @State private var ruleToDelete: WAFRule? = nil
    @State private var showingDeleteSnippetAlert = false
    @State private var showingDeleteRuleAlert = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            contentView
        }
        .navigationTitle("Edge Snippets")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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
                .accessibilityLabel("添加代码片段或规则")
            }
        }
        .sheet(isPresented: $showingEditorSheet) {
            SnippetEditorSheetView(zoneId: zoneId, existingSnippet: editingSnippet, viewModel: viewModel)
        }
        .sheet(isPresented: $showingBindSheet) {
            BindSnippetRuleSheetView(zoneId: zoneId, snippets: viewModel.snippets, viewModel: viewModel)
        }
        .alert("Delete Snippet", isPresented: $showingDeleteSnippetAlert, presenting: snippetToDelete) { snip in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    _ = await viewModel.deleteSnippet(zoneId: zoneId, snippetName: snip.snippet_name)
                }
            }
        } message: { snip in
            Text("Are you sure you want to delete snippet '\(snip.snippet_name)'?")
        }
        .alert("Delete Trigger Rule", isPresented: $showingDeleteRuleAlert, presenting: ruleToDelete) { rule in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let rId = viewModel.rulesetId {
                    Task {
                        _ = await viewModel.deleteSnippetRule(zoneId: zoneId, rulesetId: rId, ruleId: rule.id)
                    }
                }
            }
        } message: { rule in
            Text("Are you sure you want to remove trigger rule '\(rule.description ?? "Rule")'?")
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
            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                Section {
                    EmptyStateView.error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task {
                                await viewModel.fetchSnippets(zoneId: zoneId)
                            }
                        }
                    )
                }
                .listRowBackground(Color.clear)
            } else if viewModel.snippets.isEmpty && viewModel.rules.isEmpty && viewModel.hasFetchedData {
                Section {
                    EmptyStateView(
                        icon: "curlybraces",
                        title: "No Edge Snippets",
                        message: "Deploy lightweight JavaScript logic to the Cloudflare edge directly for this zone.",
                        actionTitle: "New Snippet",
                        action: {
                            editingSnippet = nil
                            showingEditorSheet = true
                        }
                    )
                }
                .listRowBackground(Color.clear)
            } else {
                // Section 1: Snippet Scripts
                Section(header: Text("Snippet Scripts (\(viewModel.snippets.count))")) {
                    if viewModel.snippets.isEmpty {
                        Text("No snippet scripts uploaded.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.snippets) { snip in
                            Button {
                                editingSnippet = snip
                                showingEditorSheet = true
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Color.orange.opacity(0.12)
                                        Image(systemName: "curlybraces")
                                            .foregroundStyle(.orange)
                                            .font(.body)
                                            .accessibilityHidden(true)
                                    }
                                    .frame(width: 36, height: 36)
                                    .cornerRadius(8)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(snip.snippet_name)
                                            .font(.body)
                                            .foregroundStyle(.primary)

                                        if let modified = snip.modifiedOn {
                                            Text("Modified: \(String(modified.prefix(10)))")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 3)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    snippetToDelete = snip
                                    showingDeleteSnippetAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                // Section 2: Snippet Rules (Routing)
                Section(header: Text("Execution Rules (\(viewModel.rules.count))"), footer: Text("Rules determine which HTTP requests execute specific snippets based on expression filters.")) {
                    if viewModel.rules.isEmpty {
                        Text("No rules attached. Add a rule to trigger your snippets.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.rules) { rule in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(rule.description ?? "Snippet Trigger Rule")
                                        .font(.body)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    let isEnabled = rule.enabled
                                    Text(isEnabled ? "Active" : "Disabled")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background((isEnabled ? Color.green : Color.gray).opacity(0.15))
                                        .foregroundStyle(isEnabled ? .green : .secondary)
                                        .cornerRadius(4)
                                }
                                
                                if let snipName = rule.action_parameters?.snippet_name {
                                    HStack(spacing: 4) {
                                        Image(systemName: "curlybraces")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                        Text("Snippet: \(snipName)")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                }
                                
                                Text(rule.expression)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    ruleToDelete = rule
                                    showingDeleteRuleAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

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
                            Text(snip.snippet_name).tag(snip.snippet_name)
                        }
                    }
                }
                
                Section(header: Text("Rule Description")) {
                    TextField("e.g. Route /api requests to snippet", text: $ruleDescription)
                }
                
                Section(header: Text("Matching Expression"), footer: Text("Requests matching this wirefilter expression will execute the selected snippet.")) {
                    TextField("Expression", text: $expression)
                        .font(.footnote)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Trigger Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
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
                                dismiss()
                            }
                            isBinding = false
                        }
                    }
                    .disabled(selectedSnippetName.isEmpty || expression.trimmingCharacters(in: .whitespaces).isEmpty || isBinding)
                }
            }
            .onAppear {
                if selectedSnippetName.isEmpty, let first = snippets.first {
                    selectedSnippetName = first.snippet_name
                }
            }
            .toastContainer()
        }
    }
}

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
                Section(header: Text("Snippet Name"), footer: Text("Allowed characters: letters, numbers, and underscores.")) {
                    TextField("my_snippet", text: $snippetName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(existingSnippet != nil)
                }
                
                Section(header: Text("JavaScript Code (ES Module)")) {
                    TextEditor(text: $code)
                        .font(.footnote)
                        .frame(minHeight: 180)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(existingSnippet == nil ? "New Snippet" : existingSnippet!.snippet_name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
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
                                dismiss()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(snippetName.trimmingCharacters(in: .whitespaces).isEmpty || code.isEmpty || isSaving)
                }
            }
            .task {
                if let ex = existingSnippet {
                    snippetName = ex.snippet_name
                    if let fetched = await viewModel.loadSnippetContent(zoneId: zoneId, name: ex.snippet_name), !fetched.isEmpty {
                        code = fetched
                    }
                }
            }
            .toastContainer()
        }
    }
}
