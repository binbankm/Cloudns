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
        List {
            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else {
                // Section: Bucket Info
                Section(header: Text("Bucket Information")) {
                    HStack {
                        Text("Bucket Name")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(bucket.name)
                            .font(.body.monospacedDigit())
                            .foregroundColor(.primary)
                    }
                    
                    if let loc = bucket.location {
                        HStack {
                            Text("Location")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(loc.uppercased())
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if let date = bucket.creationDate {
                        HStack {
                            Text("Created On")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(date.prefix(10)))
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // Section: Objects List
                Section(header: Text("Objects (\(viewModel.objects.count))")) {
                    if viewModel.objects.isEmpty {
                        Text("No objects stored in this bucket.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else if viewModel.filteredObjects.isEmpty {
                        EmptyStateView.search(query: viewModel.searchText) {
                            viewModel.searchText = ""
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    } else {
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
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct R2ObjectRowView: View {
    let object: R2Object
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: fileIcon(for: object.key))
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(object.key)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    Text(object.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let up = object.uploaded {
                        Text(String(up.prefix(10)))
                            .font(.caption)
                            .foregroundColor(.secondary)
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
