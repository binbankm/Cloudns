import Foundation
import SwiftUI

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
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $viewModel.searchText,
                prompt: "Search Lists"
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(Color(.systemGroupedBackground))
            
            List {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section {
                        ForEach(RedirectList.placeholders) { placeholder in
                            listRow(placeholder)
                        }
                    }
                    .skeletonLoading(true)
                } else if !viewModel.filteredLists.isEmpty {
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
            .scrollDismissesKeyboard(.interactively)
            .centerConstrainedWidth(maxWidth: 840)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Redirect Lists")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create List")
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateBulkRedirectListSheetView(viewModel: viewModel)
        }
        .confirmationDialog("Delete List", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: listToDelete) { item in
            Button("Delete '\(item.name)'", role: .destructive) {
                Task { await viewModel.deleteList(id: item.id) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text("Are you sure you want to delete redirect list '\(item.name)'?")
        }
        .refreshable {
            await viewModel.fetchLists()
        }
        .overlay {
            if viewModel.hasFetchedData {
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
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchLists()
            }
        }
    }
    
    @ViewBuilder
    private func listRow(_ list: RedirectList) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.swap")
                .foregroundStyle(.indigo)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(Color.indigo.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(list.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let desc = list.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if let count = list.count {
                Text("\(count) items")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
