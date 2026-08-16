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
                    .accessibilityLabel("创建 R2 存储桶")
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
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                Section {
                    EmptyStateView.error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task { await viewModel.fetchBuckets() }
                        }
                    )
                }
                .listRowBackground(Color.clear)
            } else if viewModel.buckets.isEmpty {
                Section {
                    EmptyStateView(
                        icon: "externaldrive.badge.icloud",
                        title: "No R2 Buckets",
                        message: "You haven't created any R2 storage buckets in this account yet.",
                        actionTitle: "Create Bucket",
                        action: { showingCreateSheet = true }
                    )
                }
                .listRowBackground(Color.clear)
            } else if viewModel.filteredBuckets.isEmpty {
                Section {
                    EmptyStateView.search(query: viewModel.searchText) {
                        viewModel.searchText = ""
                    }
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
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
    
    private var normalizedBucketName: String {
        bucketName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    private var isValidBucketName: Bool {
        let name = normalizedBucketName
        guard name.count >= 3 && name.count <= 63 else { return false }
        let pattern = "^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$"
        return name.range(of: pattern, options: .regularExpression) != nil
    }
    
    private var validationHint: String? {
        let name = normalizedBucketName
        if name.isEmpty {
            return nil
        }
        if name.count < 3 {
            return "Bucket name must be at least 3 characters long."
        }
        if name.count > 63 {
            return "Bucket name cannot exceed 63 characters."
        }
        let pattern = "^[a-z0-9][a-z0-9-]*[a-z0-9]$"
        if name.range(of: pattern, options: .regularExpression) == nil {
            return "Only lowercase letters, numbers, and hyphens (-) allowed. Cannot start or end with a hyphen."
        }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Bucket Information"), footer: Text("3-63 characters, lowercase letters, numbers, and hyphens only.")) {
                    TextField("my-bucket-name", text: $bucketName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: bucketName) { newValue in
                            let lower = newValue.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
                            if lower != newValue {
                                bucketName = lower
                            }
                        }
                    
                    Picker("Location Hint", selection: $selectedLocation) {
                        ForEach(locations, id: \.0) { loc in
                            Text(loc.1).tag(loc.0)
                        }
                    }
                }
                
                if let hint = validationHint {
                    Section {
                        Label(hint, systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
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
                                try await viewModel.createBucket(name: normalizedBucketName, locationHint: locHint)
                                ToastManager.shared.showSuccess("R2 Storage", message: "Bucket created successfully")
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isCreating = false
                        }
                    }
                    .disabled(!isValidBucketName || isCreating)
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
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(bucket.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 10) {
                    if let loc = bucket.location, !loc.isEmpty {
                        Text(loc.uppercased())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let date = bucket.creationDate {
                        Text(String(date.prefix(10)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Text("S3 Compatible")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
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
