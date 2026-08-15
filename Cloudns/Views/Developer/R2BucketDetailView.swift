import SwiftUI

struct R2BucketDetailView: View {
    let accountId: String
    let bucket: R2Bucket
    @StateObject private var viewModel: R2BucketDetailViewModel
    
    init(accountId: String, bucket: R2Bucket) {
        self.accountId = accountId
        self.bucket = bucket
        _viewModel = StateObject(wrappedValue: R2BucketDetailViewModel(accountId: accountId, bucket: bucket))
    }
    
    var body: some View {
        contentView
            .navigationTitle(bucket.name)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Objects in Bucket")
            .refreshable {
                await viewModel.fetchObjects()
            }
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchObjects()
                }
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading && !viewModel.hasFetchedData {
                List {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
                .listStyle(.insetGrouped)
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                EmptyStateView.error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task { await viewModel.fetchObjects() }
                    }
                )
            } else if viewModel.objects.isEmpty {
                EmptyStateView(
                    icon: "externaldrive.badge.icloud",
                    title: "No Objects in Bucket",
                    message: "This R2 bucket is currently empty. Upload objects to get started.",
                    actionTitle: nil,
                    action: nil
                )
            } else if viewModel.filteredObjects.isEmpty {
                EmptyStateView.search(query: viewModel.searchText) {
                    viewModel.searchText = ""
                }
            } else {
                List {
                    // Section: Bucket Info
                    Section(header: Text("Bucket Information")) {
                        HStack {
                            Text("Bucket Name")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(bucket.name)
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                        
                        if let loc = bucket.location {
                            HStack {
                                Text("Location")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(loc.uppercased())
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        if let date = bucket.creationDate {
                            HStack {
                                Text("Created On")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(String(date.prefix(10)))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    
                    // Section: Objects List
                    Section(header: Text("Objects (\(viewModel.objects.count))")) {
                        ForEach(viewModel.filteredObjects) { obj in
                            R2ObjectRowView(object: obj)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task {
                                            do {
                                                try await viewModel.deleteObject(key: obj.key)
                                                ToastManager.shared.showSuccess("Object Deleted", message: obj.key)
                                            } catch {
                                                ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                                            }
                                        }
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

struct R2ObjectRowView: View {
    let object: R2Object
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: fileIcon(for: object.key))
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(object.key)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    Text(object.formattedSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let up = object.uploaded {
                        Text(String(up.prefix(10)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 3)
        .contextMenu {
            Button {
                UIPasteboard.general.string = object.key
                ToastManager.shared.showCopied("Object key copied")
            } label: {
                Label("Copy Object Key", systemImage: "doc.on.doc")
            }
        }
    }
    
    private func fileIcon(for key: String) -> String {
        let lower = key.lowercased()
        if lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".webp") || lower.hasSuffix(".svg") {
            return "photo.fill"
        } else if lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") || lower.hasSuffix(".webm") {
            return "film.fill"
        } else if lower.hasSuffix(".json") || lower.hasSuffix(".js") || lower.hasSuffix(".ts") || lower.hasSuffix(".html") || lower.hasSuffix(".css") {
            return "chevron.left.forwardslash.chevron.right"
        } else if lower.hasSuffix(".zip") || lower.hasSuffix(".tar") || lower.hasSuffix(".gz") {
            return "archivebox.fill"
        }
        return "doc.fill"
    }
}
