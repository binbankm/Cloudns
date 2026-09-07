import SwiftUI
import UniformTypeIdentifiers

// MARK: - R2BucketDetailView
// Apple HIG Compliant Cloudflare R2 Object Storage Bucket Explorer

struct R2BucketDetailView: View {
    let accountId: String
    let bucket: R2Bucket
    @StateObject private var viewModel: R2BucketDetailViewModel
    @State private var showingUploadSheet = false
    @State private var selectedObject: R2Object?
    @State private var objectToDelete: R2Object?
    @State private var showingDeleteConfirm = false
    
    init(accountId: String, bucket: R2Bucket) {
        self.accountId = accountId
        self.bucket = bucket
        _viewModel = StateObject(wrappedValue: R2BucketDetailViewModel(accountId: accountId, bucket: bucket))
    }
    
    var body: some View {
        List {
            if !viewModel.objects.isEmpty {
                Section("Bucket Information") {
                    if let created = bucket.creationDate, let date = DateFormatters.parseISO8601(created) {
                        LabeledContent("Created") {
                            Text(date.displayFormatted(date: .abbreviated, time: .omitted))
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if let loc = bucket.location {
                        LabeledContent("Location") {
                            Text(loc.uppercased())
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            if !viewModel.filteredObjects.isEmpty {
                Section("Objects (\(viewModel.filteredObjects.count))") {
                    ForEach(viewModel.filteredObjects) { obj in
                        Button {
                            selectedObject = obj
                        } label: {
                            R2ObjectRowView(object: obj)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                copyToClipboard(obj.key, toast: "Object Key Copied")
                            } label: {
                                Label("Copy Key", systemImage: "doc.on.doc")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                objectToDelete = obj
                                showingDeleteConfirm = true
                            } label: {
                                Label("Delete Object", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                objectToDelete = obj
                                showingDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Objects…",
            isEmpty: viewModel.hasFetchedData && viewModel.objects.isEmpty && viewModel.errorMessage == nil,
            emptyTitle: "No Objects in Bucket",
            emptySystemImage: "tray.and.arrow.up",
            emptyDescription: "This R2 bucket is currently empty. Upload objects to get started.",
            emptyActionTitle: "Upload Object",
            emptyAction: { showingUploadSheet = true },
            isSearchEmpty: viewModel.hasFetchedData && !viewModel.objects.isEmpty && viewModel.filteredObjects.isEmpty && !viewModel.searchText.isEmpty,
            searchQuery: viewModel.searchText,
            errorMessage: viewModel.errorMessage.map { LocalizedStringKey($0) },
            retryAction: { Task { await viewModel.fetchObjects() } }
        )
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Objects in Bucket"
        )
        .navigationTitle(bucket.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchObjects()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
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
        .confirmationDialog("Delete Object", isPresented: $showingDeleteConfirm, titleVisibility: .visible, presenting: objectToDelete) { obj in
            Button("Delete '\(obj.key)'", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteObject(key: obj.key)
                        ToastManager.shared.showSuccess("Object Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                    } catch {
                        ToastManager.shared.showError("Failed to Delete Object")
                        HapticManager.notification(.error)
                    }
                    objectToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                objectToDelete = nil
            }
        } message: { obj in
            Text("Are you sure you want to delete object '\(obj.key)'? This cannot be undone.")
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchObjects()
            }
        }
    }
}

// MARK: - R2ObjectRowView (Inlined & Cohesive)

struct R2ObjectRowView: View {
    let object: R2Object
    
    private var fileIcon: String {
        let ext = (object.key as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "webp", "gif", "svg": return "photo"
        case "mp4", "mov", "webm": return "film"
        case "mp3", "wav", "aac": return "waveform"
        case "json", "js", "ts", "html", "css", "py": return "curlybraces"
        case "zip", "tar", "gz": return "doc.zipper"
        case "pdf": return "doc.text.fill"
        default: return "doc"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ListRowIcon(icon: fileIcon, color: .blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(object.key)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(ByteCountFormatter.string(fromByteCount: Int64(object.size), countStyle: .file))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                    
                    if let uploaded = object.uploaded, let date = DateFormatters.parseISO8601(uploaded) {
                        Text(date.displayFormatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - R2UploadObjectSheetView (Inlined & Cohesive)

struct R2UploadObjectSheetView: View {
    @ObservedObject var viewModel: R2BucketDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var objectKey = ""
    @State private var textContent = ""
    @State private var contentType = "text/plain"
    @State private var isUploading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("my-file.txt", text: $objectKey)
                        .font(.body.monospaced())
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Object Key")
                } footer: {
                    Text("Path/filename in the bucket (e.g. assets/config.json).")
                }
                
                Section("Content Type") {
                    TextField("text/plain", text: $contentType)
                        .font(.body.monospaced())
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section("Text Content") {
                    TextEditor(text: $textContent)
                        .font(.footnote.monospaced())
                        .frame(minHeight: 140)
                }
                
                if let err = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(verbatim: err)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Upload Object")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Upload") {
                        Task {
                            isUploading = true
                            errorMessage = nil
                            do {
                                let data = textContent.data(using: .utf8) ?? Data()
                                try await viewModel.uploadObject(
                                    key: objectKey.trimmingCharacters(in: .whitespaces),
                                    data: data,
                                    contentType: contentType
                                )
                                ToastManager.shared.showSuccess("Object Uploaded", icon: "arrow.up.doc.fill")
                                HapticManager.notification(.success)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.notification(.error)
                            }
                            isUploading = false
                        }
                    }
                    .disabled(objectKey.trimmingCharacters(in: .whitespaces).isEmpty || isUploading)
                }
            }
            .interactiveDismissDisabled(isUploading)
        }
    }
}

// MARK: - R2ObjectDetailSheetView (Inlined & Cohesive)

struct R2ObjectDetailSheetView: View {
    @ObservedObject var viewModel: R2BucketDetailViewModel
    let object: R2Object
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Object Details") {
                    LabeledContent("Key", value: object.key)
                    LabeledContent("Size", value: ByteCountFormatter.string(fromByteCount: Int64(object.size), countStyle: .file))
                    if let etag = object.etag {
                        LabeledContent("ETag", value: etag)
                    }
                    if let uploaded = object.uploaded, let date = DateFormatters.parseISO8601(uploaded) {
                        LabeledContent("Uploaded") {
                            Text(date.displayFormatted(date: .abbreviated, time: .standard))
                        }
                    }
                    if let storageClass = object.storageClass {
                        LabeledContent("Storage Class", value: storageClass)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        HapticManager.impact(.medium)
                        Task {
                            try? await viewModel.deleteObject(key: object.key)
                            ToastManager.shared.showSuccess("Object Deleted", icon: "trash.fill")
                            HapticManager.notification(.success)
                            dismiss()
                        }
                    } label: {
                        Text("Delete Object")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Object Info")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
