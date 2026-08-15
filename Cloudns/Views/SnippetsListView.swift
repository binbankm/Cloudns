import SwiftUI

struct SnippetsListView: View {
    let zoneId: String
    @StateObject private var viewModel = SnippetsViewModel()
    @State private var showingEditorSheet = false
    @State private var editingSnippet: SnippetItem? = nil
    @State private var snippetToDelete: SnippetItem? = nil
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            contentView
        }
        .navigationTitle("Edge Snippets")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editingSnippet = nil
                    showingEditorSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("添加代码片段")
            }
        }
        .sheet(isPresented: $showingEditorSheet) {
            SnippetEditorSheetView(zoneId: zoneId, existingSnippet: editingSnippet, viewModel: viewModel)
        }
        .alert("Delete Snippet", isPresented: $showingDeleteAlert, presenting: snippetToDelete) { snip in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteSnippet(zoneId: zoneId, snippetName: snip.snippet_name)
                }
            }
        } message: { snip in
            Text("Are you sure you want to delete snippet '\(snip.snippet_name)'?")
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
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)

            if viewModel.isLoading && !viewModel.hasFetchedData {
                List {
                    ForEach(0..<6, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
                .listStyle(.insetGrouped)
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                EmptyStateView.error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task {
                            await viewModel.fetchSnippets(zoneId: zoneId)
                        }
                    }
                )
            } else if viewModel.snippets.isEmpty && viewModel.hasFetchedData {
                EmptyStateView(
                    icon: "curlybraces",
                    title: "No Edge Snippets",
                    message: "Deploy lightweight JavaScript logic to the Cloudflare edge directly for this zone."
                )
            } else {
                List {
                    Section(header: Text("Active Snippets (\(viewModel.snippets.count))")) {
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
                                            .font(.body.monospacedDigit())
                                            .foregroundStyle(.primary)

                                        if let mod = snip.modifiedOn {
                                            Text("Modified: \(String(mod.prefix(10)))")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Color(UIColor.tertiaryLabel))
                                        .accessibilityHidden(true)
                                }
                                .padding(.vertical, 3)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    snippetToDelete = snip
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
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
