import Foundation
import SwiftUI
import Combine

@MainActor
final class BulkRedirectsViewModel: ObservableObject {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var lists: [RedirectList] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var hasFetchedData: Bool = false
    @Published var errorMessage: String? = nil
    
    init(accountId: String) {
        self.accountId = accountId
    }
    
    var filteredLists: [RedirectList] {
        if searchText.isEmpty { return lists }
        return lists.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchLists() async {
        isLoading = true
        errorMessage = nil
        do {
            self.lists = try await apiClient.listRedirectLists(accountId: accountId)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.hasFetchedData = true
        }
        isLoading = false
    }
    
    func createList(name: String, description: String?) async -> Bool {
        do {
            _ = try await apiClient.createRedirectList(accountId: accountId, name: name, description: description)
            ToastManager.shared.showSuccess("List Created", message: name)
            await fetchLists()
            return true
        } catch {
            ToastManager.shared.showError("Create Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteList(id: String) async {
        do {
            try await apiClient.deleteRedirectList(accountId: accountId, listId: id)
            ToastManager.shared.showSuccess("List Deleted", message: "")
            await fetchLists()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}

struct BulkRedirectListsView: View {
    let accountId: String
    @StateObject private var viewModel: BulkRedirectsViewModel
    @State private var showingCreateSheet = false
    @State private var listToDelete: RedirectList?
    @State private var showingDeleteAlert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: BulkRedirectsViewModel(accountId: accountId))
    }
    
    var body: some View {
        Group {
            if !viewModel.hasFetchedData {
                List {
                    Section(header: Text("Redirect Lists")) {
                        ForEach(RedirectList.placeholders) { item in
                            listRow(item)
                        }
                    }
                    .skeletonLoading(true)
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Bulk Redirects")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                contentView
                    .navigationTitle("Bulk Redirects")
                    .navigationBarTitleDisplayMode(.inline)
                    .searchable(text: $viewModel.searchText, prompt: "Search Lists")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingCreateSheet = true
                            } label: {
                                Image(systemName: "plus")
                            }
                            .accessibilityLabel("Create List")
                        }
                    }
                    .sheet(isPresented: $showingCreateSheet) {
                        CreateBulkRedirectListSheet(viewModel: viewModel)
                    }
                    .alert("Delete List", isPresented: $showingDeleteAlert, presenting: listToDelete) { item in
                        Button("Cancel", role: .cancel) {}
                        Button("Delete", role: .destructive) {
                            Task { await viewModel.deleteList(id: item.id) }
                        }
                    } message: { item in
                        Text("Are you sure you want to delete redirect list '\(item.name)'?")
                    }
                    .refreshable {
                        await viewModel.fetchLists()
                    }
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchLists()
            }
        }
        .toastContainer()
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if !viewModel.filteredLists.isEmpty {
                Section(header: Text("Redirect Lists (\(viewModel.lists.count))")) {
                    ForEach(viewModel.filteredLists) { item in
                        NavigationLink(destination: RedirectListDetailView(accountId: accountId, list: item)) {
                            listRow(item)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                listToDelete = item
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
        .overlay {
            if let err = viewModel.errorMessage, viewModel.lists.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(err),
                            retryAction: { Task { await viewModel.fetchLists() } }
                        )
                    )
                } else if viewModel.lists.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "arrow.triangle.swap",
                            title: "No Bulk Redirect Lists",
                            message: "Bulk Redirects allow you to define thousands of URL redirects at the account level.",
                            actionTitle: "Create List",
                            action: { showingCreateSheet = true }
                        )
                    )
                } else if viewModel.filteredLists.isEmpty && !viewModel.searchText.isEmpty {
                    StateOverlayView(
                        state: .search(
                            query: viewModel.searchText,
                            clearAction: { viewModel.searchText = "" }
                        )
                    )
                }
        }
    }
    
    @ViewBuilder
    private func listRow(_ item: RedirectList) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.swap")
                .foregroundStyle(.indigo)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(Color.indigo.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.body.weight(.medium))
                
                if let desc = item.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let count = item.count {
                Text("\(count) items")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct RedirectListDetailView: View {
    let accountId: String
    let list: RedirectList
    @State private var items: [RedirectListItem] = []
    @State private var isLoading = false
    @State private var showingAddSheet = false
    
    var body: some View {
        List {
            Section(header: Text("List Metadata")) {
                HStack {
                    Text("Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(list.name)
                        .font(.body.weight(.medium))
                }
                
                HStack {
                    Text("List ID")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(list.id)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            
            Section(header: Text("Redirect Items (\(items.count))")) {
                if isLoading && items.isEmpty {
                    ProgressView()
                } else if items.isEmpty {
                    Text("No redirect items in this list.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.redirect.sourceUrl)
                                    .font(.caption.monospaced())
                                Spacer()
                                Text("\(item.redirect.statusCode ?? 301)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.indigo)
                            }
                            
                            HStack {
                                Image(systemName: "arrow.turn.down.right")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .accessibilityHidden(true)
                                Text(item.redirect.targetUrl)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.vertical, 2)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                Task { await deleteItem(id: item.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Redirect Item")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddRedirectItemSheet(accountId: accountId, listId: list.id) {
                Task { await fetchItems() }
            }
        }
        .task {
            await fetchItems()
        }
        .toastContainer()
    }
    
    private func fetchItems() async {
        isLoading = true
        do {
            self.items = try await CloudflareAPIClient.shared.listRedirectListItems(accountId: accountId, listId: list.id)
        } catch {
            print("Failed to load items: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    private func deleteItem(id: String) async {
        do {
            _ = try await CloudflareAPIClient.shared.deleteRedirectListItems(accountId: accountId, listId: list.id, itemIds: [id])
            ToastManager.shared.showSuccess("Item Deleted", message: "")
            await fetchItems()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}

struct AddRedirectItemSheet: View {
    let accountId: String
    let listId: String
    let onAdded: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var sourceUrl = ""
    @State private var targetUrl = ""
    @State private var statusCode = 301
    @State private var preserveQueryString = true
    @State private var subpathMatching = false
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Source URL")) {
                    TextField("https://old.example.com/page", text: $sourceUrl)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Target URL")) {
                    TextField("https://new.example.com/target", text: $targetUrl)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Settings")) {
                    Picker("Status Code", selection: $statusCode) {
                        Text("301 Permanent Redirect").tag(301)
                        Text("302 Temporary Redirect").tag(302)
                        Text("307 Temporary Redirect").tag(307)
                        Text("308 Permanent Redirect").tag(308)
                    }
                    
                    Toggle("Preserve Query String", isOn: $preserveQueryString)
                    Toggle("Subpath Matching", isOn: $subpathMatching)
                }
            }
            .navigationTitle("New Redirect Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        Task {
                            isSubmitting = true
                            let item = RedirectItemDetail(
                                sourceUrl: sourceUrl.trimmingCharacters(in: .whitespacesAndNewlines),
                                targetUrl: targetUrl.trimmingCharacters(in: .whitespacesAndNewlines),
                                statusCode: statusCode,
                                preserveQueryString: preserveQueryString,
                                includeSubdomains: false,
                                subpathMatching: subpathMatching,
                                preservePathSuffix: false
                            )
                            do {
                                _ = try await CloudflareAPIClient.shared.createRedirectListItems(accountId: accountId, listId: listId, items: [item])
                                ToastManager.shared.showSuccess("Item Added", message: "")
                                onAdded()
                                dismiss()
                            } catch {
                                ToastManager.shared.showError("Add Failed", message: error.localizedDescription)
                            }
                            isSubmitting = false
                        }
                    }
                    .disabled(sourceUrl.isEmpty || targetUrl.isEmpty || isSubmitting)
                }
            }
        }
    }
}

struct CreateBulkRedirectListSheet: View {
    @ObservedObject var viewModel: BulkRedirectsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("List Name")) {
                    TextField("marketing-redirects", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Description (Optional)")) {
                    TextField("Redirects for domain migration", text: $description)
                }
            }
            .navigationTitle("New Redirect List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            isSubmitting = true
                            let clean = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                            let success = await viewModel.createList(name: clean, description: description.isEmpty ? nil : description)
                            if success { dismiss() }
                            isSubmitting = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
        }
    }
}
