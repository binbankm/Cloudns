import SwiftUI

struct SnippetsListView: View {
    let zoneId: String
    @State private var snippets: [SnippetItem] = []
    @State private var isLoading = false
    @State private var hasFetchedData = false
    @State private var errorMessage: String?
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
            }
        }
        .sheet(isPresented: $showingEditorSheet) {
            SnippetEditorSheetView(zoneId: zoneId, existingSnippet: editingSnippet) {
                Task { await fetchSnippets() }
            }
        }
        .alert("Delete Snippet", isPresented: $showingDeleteAlert, presenting: snippetToDelete) { snip in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await CloudflareAPIClient.shared.deleteSnippet(zoneId: zoneId, snippetName: snip.snippet_name)
                        ToastManager.shared.showSuccess("Snippet Deleted", message: snip.snippet_name)
                        await fetchSnippets()
                    } catch {
                        ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                    }
                }
            }
        } message: { snip in
            Text("Are you sure you want to delete snippet '\(snip.snippet_name)'?")
        }
        .refreshable {
            await fetchSnippets()
        }
        .task {
            if !hasFetchedData {
                await fetchSnippets()
            }
        }
        .toastContainer()
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if isLoading && !hasFetchedData {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonRowView()
                }
            } else if let err = errorMessage, !hasFetchedData {
                EmptyStateView.error(
                    message: LocalizedStringKey(err),
                    retryAction: { Task { await fetchSnippets() } }
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else if snippets.isEmpty {
                EmptyStateView(
                    icon: "curlybraces",
                    title: "No Snippets Found",
                    message: "Cloudflare Snippets allow executing lightweight JavaScript logic on HTTP requests without full Workers.",
                    actionTitle: "Create Snippet",
                    action: {
                        editingSnippet = nil
                        showingEditorSheet = true
                    }
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else {
                Section(header: Text("Snippets (\(snippets.count))"), footer: Text("Snippets run micro JavaScript functions on HTTP requests with sub-millisecond execution time.")) {
                    ForEach(snippets) { snip in
                        Button {
                            editingSnippet = snip
                            showingEditorSheet = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "curlybraces")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.orange)
                                    .frame(width: 32, height: 32)
                                    .background(Color.orange.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(snip.snippet_name)
                                        .font(.body.monospaced())
                                        .foregroundColor(.primary)
                                    
                                    if let mod = snip.modifiedOn {
                                        Text("Modified: \(String(mod.prefix(10)))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(Color(UIColor.tertiaryLabel))
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
        }
        .listStyle(.insetGrouped)
    }
    
    private func fetchSnippets() async {
        isLoading = true
        errorMessage = nil
        do {
            self.snippets = try await CloudflareAPIClient.shared.getSnippets(zoneId: zoneId)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct SnippetEditorSheetView: View {
    let zoneId: String
    let existingSnippet: SnippetItem?
    var onSaved: () -> Void
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
                        .font(.system(size: 13, design: .monospaced))
                        .frame(minHeight: 180)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
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
                            do {
                                try await CloudflareAPIClient.shared.putSnippet(
                                    zoneId: zoneId,
                                    name: snippetName.trimmingCharacters(in: .whitespaces),
                                    code: code
                                )
                                ToastManager.shared.showSuccess("Snippet", message: "Snippet saved successfully")
                                onSaved()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
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
                    if let fetched = try? await CloudflareAPIClient.shared.getSnippetContent(zoneId: zoneId, name: ex.snippet_name), !fetched.isEmpty {
                        code = fetched
                    }
                }
            }
            .toastContainer()
        }
    }
}
