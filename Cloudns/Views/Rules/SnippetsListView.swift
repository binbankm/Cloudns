import SwiftUI

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
    @State private var searchText = ""
    
    private var displayedSnippets: [SnippetItem] {
        if searchText.isEmpty { return viewModel.snippets }
        return viewModel.snippets.filter { $0.snippet_name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var displayedRules: [WAFRule] {
        if searchText.isEmpty { return viewModel.rules }
        return viewModel.rules.filter {
            ($0.description ?? "").localizedCaseInsensitiveContains(searchText) ||
            $0.expression.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        contentView
            .navigationTitle("Edge Snippets")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Snippets & Rules")
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
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section(header: Text("Snippet Scripts")) {
                    ForEach(SnippetItem.placeholders) { placeholderSnippet in
                        snippetRow(placeholderSnippet)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
            } else if !displayedSnippets.isEmpty || !displayedRules.isEmpty {
                // MARK: - Snippet Scripts
                Section(header: Text("Snippet Scripts (\(displayedSnippets.count))")) {
                    if displayedSnippets.isEmpty {
                        Text("No snippet scripts uploaded.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(displayedSnippets) { snip in
                            snippetRow(snip)
                        }
                    }
                }

                // MARK: - Snippet Rules (Routing)
                Section(
                    header: Text("Execution Rules (\(displayedRules.count))"),
                    footer: Text("Rules determine which HTTP requests execute specific snippets based on expression filters.")
                ) {
                    if displayedRules.isEmpty {
                        Text("No trigger rules configured.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(displayedRules) { rule in
                            ruleRow(rule)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.snippets.isEmpty && viewModel.rules.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchSnippets(zoneId: zoneId) }
                            }
                        )
                    )
                } else if viewModel.snippets.isEmpty && viewModel.rules.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "curlybraces",
                            title: "No Edge Snippets",
                            message: "Deploy lightweight JavaScript logic to the Cloudflare edge directly for this zone.",
                            actionTitle: "New Snippet",
                            action: {
                                editingSnippet = nil
                                showingEditorSheet = true
                            }
                        )
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func snippetRow(_ snip: SnippetItem) -> some View {
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
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text(snip.snippet_name)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if let modified = snip.modifiedOn {
                        Text("Modified: \(DateFormatters.formatISO8601ToDisplay(modified, style: DateFormatters.dateOnly))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 3)
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
                Text(rule.description ?? "Snippet Trigger Rule")
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                let isEnabled = rule.enabled
                Text(isEnabled ? "Active" : "Disabled")
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((isEnabled ? Color.green : Color.gray).opacity(0.15))
                    .foregroundStyle(isEnabled ? .green : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            if let snipName = rule.action_parameters?.snippet_name {
                HStack(spacing: 4) {
                    Image(systemName: "curlybraces")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)
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
                HapticManager.impact(.medium)
                ruleToDelete = rule
                showingDeleteRuleAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
