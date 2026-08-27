import SwiftUI

struct SnippetsListView: View {
    // MARK: - Properties
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
        return viewModel.snippets.filter { $0.snippet_name.localizedStandardContains(searchText) }
    }
    
    private var displayedRules: [WAFRule] {
        if searchText.isEmpty { return viewModel.rules }
        return viewModel.rules.filter {
            ($0.description ?? "").localizedStandardContains(searchText) ||
            $0.expression.localizedStandardContains(searchText)
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $searchText,
                prompt: "Search Snippets & Rules"
            )
            .padding(.horizontal, CloudnsSpacing.md)
            .padding(.top, CloudnsSpacing.sm)
            .padding(.bottom, CloudnsSpacing.xs)
            .background(CloudnsColor.groupedBackground)
            
            contentView
        }
        .background(CloudnsColor.groupedBackground)
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
    // MARK: - Private Views
    private var contentView: some View {
        List {
            
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(SnippetItem.placeholders) { placeholderSnippet in
                        snippetRow(placeholderSnippet)
                    }
                }
                .skeletonLoading(true)
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
                    CloudnsStateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchSnippets(zoneId: zoneId) }
                            }
                        )
                    )
                } else if viewModel.snippets.isEmpty && viewModel.rules.isEmpty {
                    CloudnsStateOverlayView(
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
                } else if !searchText.isEmpty && displayedSnippets.isEmpty && displayedRules.isEmpty {
                    CloudnsStateOverlayView(
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
    private func snippetRow(_ snip: SnippetItem) -> some View {
        Button {
            editingSnippet = snip
            showingEditorSheet = true
        } label: {
            HStack(spacing: CloudnsSpacing.mdMedium) {
                ZStack {
                    CloudnsColor.warningMuted
                    Image(systemName: "curlybraces")
                        .foregroundStyle(CloudnsColor.brandAccent)
                        .font(.body)
                        .accessibilityHidden(true)
                }
                .frame(width: CloudnsSize.iconHero, height: CloudnsSize.iconHero)
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))

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
            .padding(.vertical, CloudnsSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
            HStack {
                Text(rule.description ?? "Snippet Trigger Rule")
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                let isEnabled = rule.enabled
                Text(isEnabled ? "Active" : "Disabled")
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, CloudnsSpacing.sm)
                    .padding(.vertical, CloudnsSpacing.xxs)
                    .background((isEnabled ? CloudnsColor.success : CloudnsColor.dnsOnly).opacity(0.15))
                    .foregroundStyle(isEnabled ? .green : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.xs))
            }
            
            if let snipName = rule.action_parameters?.snippet_name {
                HStack(spacing: CloudnsSpacing.xs) {
                    Image(systemName: "curlybraces")
                        .font(.caption2)
                        .foregroundStyle(CloudnsColor.brandAccent)
                        .accessibilityHidden(true)
                    Text("Snippet: \(snipName)")
                        .font(.caption)
                        .foregroundStyle(CloudnsColor.brandAccent)
                }
            }
            
            Text(rule.expression)
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, CloudnsSpacing.xs)
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
