import SwiftUI
import UniformTypeIdentifiers

struct R2BucketDetailView: View {
    let accountId: String
    let bucket: R2Bucket
    @StateObject private var viewModel: R2BucketDetailViewModel
    @State private var showingUploadSheet = false
    @State private var selectedObject: R2Object?
    
    init(accountId: String, bucket: R2Bucket) {
        self.accountId = accountId
        self.bucket = bucket
        _viewModel = StateObject(wrappedValue: R2BucketDetailViewModel(accountId: accountId, bucket: bucket))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $viewModel.searchText,
                prompt: "Search Objects in Bucket"
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(Color(.systemGroupedBackground))
            
            List {
                if !viewModel.objects.isEmpty {
                    // MARK: - Bucket Info
                    Section(header: Text("Bucket Information")) {
                        HStack {
                            Text("Created")
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let created = bucket.creationDate {
                                Text(DateFormatters.formatISO8601ToDisplay(created, style: DateFormatters.dateOnly))
                                    .font(.body.monospacedDigit())
                            }
                        }
                        
                        if let loc = bucket.location {
                            HStack {
                                Text("Location")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(loc.uppercased())
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // MARK: - Objects
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section(header: Text("Objects")) {
                        ForEach(R2Object.placeholders) { placeholder in
                            R2ObjectRowView(object: placeholder)
                        }
                    }
                    .skeletonLoading(true)
                } else if !viewModel.filteredObjects.isEmpty {
                    Section(header: Text("Objects (\(viewModel.filteredObjects.count))")) {
                        ForEach(viewModel.filteredObjects) { obj in
                            Button {
                                selectedObject = obj
                            } label: {
                                R2ObjectRowView(object: obj)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    Task {
                                        do {
                                            try await viewModel.deleteObject(key: obj.key)
                                            CloudnsToastManager.shared.showSuccess("Object Deleted", message: obj.key)
                                        } catch {
                                            CloudnsToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                                        }
                                    }
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
        .navigationTitle(bucket.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchObjects()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    NavigationLink(destination: R2BucketSettingsView(accountId: accountId, bucketName: bucket.name)) {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Bucket Settings")
                    
                    Button {
                        showingUploadSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Upload Object")
                }
            }
        }
        .sheet(isPresented: $showingUploadSheet) {
            R2UploadObjectSheetView(viewModel: viewModel)
        }
        .sheet(item: $selectedObject) { obj in
            R2ObjectDetailSheetView(viewModel: viewModel, object: obj)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.objects.isEmpty {
                    CloudnsStateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchObjects() }
                            }
                        )
                    )
                } else if viewModel.objects.isEmpty {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "externaldrive.badge.icloud",
                            title: "No Objects in Bucket",
                            message: "This R2 bucket is currently empty. Upload objects to get started.",
                            actionTitle: "Upload Object",
                            action: { showingUploadSheet = true }
                        )
                    )
                } else if viewModel.filteredObjects.isEmpty && !viewModel.searchText.isEmpty {
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
                await viewModel.fetchObjects()
            }
        }
    }
}
