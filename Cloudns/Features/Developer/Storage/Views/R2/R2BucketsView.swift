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
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $viewModel.searchText,
                prompt: "Search R2 Buckets"
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(Color(.systemGroupedBackground))
            
            List {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section {
                        ForEach(R2Bucket.placeholders) { placeholderBucket in
                            R2BucketRowView(bucket: placeholderBucket)
                        }
                    }
                    .skeletonLoading(true)
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
            .scrollDismissesKeyboard(.interactively)
            .centerConstrainedWidth(maxWidth: 840)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("R2 Object Storage")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.fetchBuckets() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
                        CloudnsToastManager.shared.showSuccess("Bucket Deleted", message: bucket.name)
                    } catch {
                        CloudnsToastManager.shared.showError("Failed to delete", message: error.localizedDescription)
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
                    CloudnsStateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchBuckets() } }
                        )
                    )
                } else if viewModel.buckets.isEmpty {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "externaldrive.badge.icloud",
                            title: "No R2 Buckets",
                            message: "You haven't created any R2 storage buckets in this account yet.",
                            actionTitle: "Create Bucket",
                            action: { showingCreateSheet = true }
                        )
                    )
                } else if viewModel.filteredBuckets.isEmpty && !viewModel.searchText.isEmpty {
                    CloudnsStateOverlayView(
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
