import SwiftUI

struct R2BucketsView: View {
    let accountId: String
    @StateObject private var viewModel: R2ViewModel
    @State private var showingCreateSheet = false
    @State private var bucketToDelete: R2Bucket? = nil
    @State private var showingDeleteAlert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: R2ViewModel(accountId: accountId))
    }
    
    var body: some View {
        contentView
            .navigationTitle("R2 Object Storage")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search R2 Buckets")
            .refreshable {
                await viewModel.fetchBuckets()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                R2CreateBucketSheetView(viewModel: viewModel)
            }
            .alert("Delete Bucket", isPresented: $showingDeleteAlert, presenting: bucketToDelete) { bucket in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteBucket(bucketName: bucket.name)
                            ToastManager.shared.showSuccess("Bucket Deleted", message: bucket.name)
                        } catch {
                            ToastManager.shared.showError("Failed to delete", message: error.localizedDescription)
                        }
                    }
                }
            } message: { bucket in
                Text("Are you sure you want to delete bucket '\(bucket.name)'? This action cannot be undone.")
            }
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchBuckets()
                }
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                EmptyStateView.error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task { await viewModel.fetchBuckets() }
                    }
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else if viewModel.buckets.isEmpty {
                EmptyStateView(
                    icon: "externaldrive.badge.icloud",
                    title: "No R2 Buckets",
                    message: "You haven't created any R2 storage buckets in this account yet.",
                    actionTitle: "Create Bucket",
                    action: { showingCreateSheet = true }
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else if viewModel.filteredBuckets.isEmpty {
                EmptyStateView.search(query: viewModel.searchText) {
                    viewModel.searchText = ""
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else {
                ForEach(viewModel.filteredBuckets) { bucket in
                    NavigationLink {
                        R2BucketDetailView(accountId: accountId, bucket: bucket)
                    } label: {
                        R2BucketRowView(bucket: bucket)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            bucketToDelete = bucket
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

struct R2CreateBucketSheetView: View {
    @ObservedObject var viewModel: R2ViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var bucketName = ""
    @State private var selectedLocation = "auto"
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    let locations = [
        ("auto", "Automatic (Best Available)"),
        ("wnam", "Western North America"),
        ("enam", "Eastern North America"),
        ("weur", "Western Europe"),
        ("eeur", "Eastern Europe"),
        ("apac", "Asia-Pacific")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Bucket Information")) {
                    TextField("Bucket Name", text: $bucketName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    Picker("Location Hint", selection: $selectedLocation) {
                        ForEach(locations, id: \.0) { loc in
                            Text(loc.1).tag(loc.0)
                        }
                    }
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Create R2 Bucket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            errorMessage = nil
                            do {
                                let locHint = selectedLocation == "auto" ? nil : selectedLocation
                                try await viewModel.createBucket(name: bucketName.trimmingCharacters(in: .whitespaces), locationHint: locHint)
                                ToastManager.shared.showSuccess("R2 Storage", message: "Bucket created successfully")
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isCreating = false
                        }
                    }
                    .disabled(bucketName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .toastContainer()
        }
    }
}

struct R2BucketRowView: View {
    let bucket: R2Bucket
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "externaldrive.fill")
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(bucket.name)
                    .font(.body)
                    .foregroundColor(.primary)
                
                HStack(spacing: 10) {
                    if let loc = bucket.location, !loc.isEmpty {
                        Text(loc.uppercased())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let date = bucket.creationDate {
                        Text(String(date.prefix(10)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Text("S3 Compatible")
                .font(.caption2.weight(.medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(UIColor.secondarySystemFill))
                .cornerRadius(4)
        }
        .padding(.vertical, 3)
        .contextMenu {
            Button {
                UIPasteboard.general.string = bucket.name
                ToastManager.shared.showCopied("Bucket name copied")
            } label: {
                Label("Copy Bucket Name", systemImage: "doc.on.doc")
            }
        }
    }
}
