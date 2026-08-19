import SwiftUI

struct R2BucketsView: View {
    let accountId: String
    @StateObject private var viewModel: R2ViewModel
    @State private var showingCreateSheet = false
    @State private var bucketToDelete: R2Bucket?
    @State private var showingDeleteAlert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: R2ViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(R2Bucket.placeholders) { placeholderBucket in
                        R2BucketRowView(bucket: placeholderBucket)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
            } else if !viewModel.filteredBuckets.isEmpty {
                Section {
                    ForEach(viewModel.filteredBuckets) { bucket in
                        NavigationLink {
                            R2BucketDetailView(accountId: accountId, bucket: bucket)
                        } label: {
                            R2BucketRowView(bucket: bucket)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                bucketToDelete = bucket
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
        .navigationTitle("R2 Object Storage")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search R2 Buckets")
        .refreshable { await viewModel.fetchBuckets() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingCreateSheet = true } label: { Image(systemName: "plus") }
                .accessibilityLabel("Create R2 Bucket")
            }
        }
        .sheet(isPresented: $showingCreateSheet) { R2CreateBucketSheetView(viewModel: viewModel) }
        .confirmationDialog("Delete Bucket", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: bucketToDelete) { bucket in
            Button("Delete '\(bucket.name)'", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteBucket(bucketName: bucket.name)
                        ToastManager.shared.showSuccess("Bucket Deleted", message: bucket.name)
                    } catch {
                        ToastManager.shared.showError("Failed to delete", message: error.localizedDescription)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { bucket in
            Text("Are you sure you want to delete bucket '\(bucket.name)'? All objects will be permanently lost.")
        }
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.buckets.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchBuckets() } }
                        )
                    )
                } else if viewModel.buckets.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "externaldrive.badge.icloud",
                            title: "No R2 Buckets",
                            message: "You haven't created any R2 storage buckets in this account yet.",
                            actionTitle: "Create Bucket",
                            action: { showingCreateSheet = true }
                        )
                    )
                } else if viewModel.filteredBuckets.isEmpty && !viewModel.searchText.isEmpty {
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
                await viewModel.fetchBuckets()
            }
        }
    }
}
