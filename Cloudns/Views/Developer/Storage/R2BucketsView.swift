import SwiftUI

// MARK: - R2BucketsView
// Apple HIG Compliant R2 Object Storage Explorer

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
            if !viewModel.filteredBuckets.isEmpty {
                Section {
                    ForEach(viewModel.filteredBuckets) { bucket in
                        NavigationLink {
                            R2BucketDetailView(accountId: accountId, bucket: bucket)
                        } label: {
                            R2BucketRowView(bucket: bucket)
                        }
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = bucket.name
                                ToastManager.shared.showCopied("Bucket Name Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy Bucket Name", systemImage: "doc.on.doc")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                bucketToDelete = bucket
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Bucket", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                bucketToDelete = bucket
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(HIGColors.error)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search R2 Buckets"
        )
        .navigationTitle("R2 Object Storage")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.fetchBuckets() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingCreateSheet = true } label: { Image(systemName: "plus") }
                .accessibilityLabel("Create R2 Bucket")
                .higTouchTarget()
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            R2CreateBucketSheetView(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .higToast()
        }
        .confirmationDialog("Delete Bucket", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: bucketToDelete) { bucket in
            Button("Delete '\(bucket.name)'", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteBucket(bucketName: bucket.name)
                        ToastManager.shared.showSuccess("Bucket Deleted", icon: "trash.fill")
                        HIGFeedback.success()
                    } catch {
                        ToastManager.shared.showError("Failed to Delete Bucket")
                        HIGFeedback.error()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { bucket in
            Text("Are you sure you want to delete bucket '\(bucket.name)'? All objects will be permanently lost.")
        }
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading R2 Buckets…"))
            } else if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.buckets.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchBuckets() } }
                        )
                    )
                } else if viewModel.buckets.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No R2 Buckets",
                            systemImage: "archivebox",
                            description: "You haven't created any R2 storage buckets in this account yet.",
                            actionTitle: "Create Bucket",
                            action: { showingCreateSheet = true }
                        )
                    )
                } else if viewModel.filteredBuckets.isEmpty && !viewModel.searchText.isEmpty {
                    HIGContentState(.search(query: viewModel.searchText))
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

// MARK: - R2BucketRowView (Inlined & Cohesive)

struct R2BucketRowView: View {
    let bucket: R2Bucket
    
    var body: some View {
        HStack(spacing: HIGTokens.Spacing.md) {
            ListRowIcon(icon: "archivebox.fill", color: .blue)
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text(bucket.name)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let created = bucket.creationDate, let date = DateFormatters.parseISO8601(created) {
                    Text("Created \(date.displayFormatted(date: .abbreviated, time: .omitted))")
                        .font(HIGTypography.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let loc = bucket.location {
                HIGBadge(.custom(color: .secondary, text: loc.uppercased()), isCompact: true)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
}

// MARK: - R2CreateBucketSheetView (Inlined & Cohesive)

struct R2CreateBucketSheetView: View {
    @ObservedObject var viewModel: R2ViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var bucketName = ""
    @State private var locationHint = "auto"
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    let locationHints = [
        ("Automatic (Recommended)", "auto"),
        ("Eastern North America", "wnam"),
        ("Western North America", "enam"),
        ("Western Europe", "weur"),
        ("Eastern Europe", "eeur"),
        ("Asia-Pacific", "apac")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Bucket Name"), footer: Text("Unique bucket name using lowercase letters, numbers, and hyphens.")) {
                    TextField("my-bucket", text: $bucketName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Location Hint")) {
                    Picker("Region", selection: $locationHint) {
                        ForEach(locationHints, id: \.1) { label, value in
                            Text(verbatim: label).tag(value)
                        }
                    }
                }
                
                if let err = errorMessage {
                    Section {
                        Text(verbatim: err)
                            .font(HIGTypography.caption)
                            .foregroundStyle(HIGColors.error)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New R2 Bucket")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            errorMessage = nil
                            do {
                                try await viewModel.createBucket(
                                    name: bucketName.trimmingCharacters(in: .whitespaces),
                                    locationHint: locationHint == "auto" ? nil : locationHint
                                )
                                ToastManager.shared.showSuccess("Bucket Created", icon: "archivebox.fill")
                                HIGFeedback.success()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
                            }
                            isCreating = false
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(bucketName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}
