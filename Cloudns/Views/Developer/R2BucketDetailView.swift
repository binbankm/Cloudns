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
        List {
            if !viewModel.objects.isEmpty {
                // Section: Bucket Info
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
                
                // Section: Objects
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section(header: Text("Objects")) {
                        ForEach(R2Object.placeholders) { placeholder in
                            R2ObjectRowView(object: placeholder)
                                .redacted(reason: .placeholder)
                                .shimmering()
                        }
                    }
                } else if !viewModel.filteredObjects.isEmpty {
                    Section(header: Text("Objects (\(viewModel.objects.count))")) {
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
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle(bucket.name)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Objects in Bucket")
        .refreshable {
            await viewModel.fetchObjects()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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
        }
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.objects.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchObjects() }
                            }
                        )
                    )
                } else if viewModel.objects.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "externaldrive.badge.icloud",
                            title: "No Objects in Bucket",
                            message: "This R2 bucket is currently empty. Upload objects to get started.",
                            actionTitle: "Upload Object",
                            action: { showingUploadSheet = true }
                        )
                    )
                } else if viewModel.filteredObjects.isEmpty && !viewModel.searchText.isEmpty {
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
                await viewModel.fetchObjects()
            }
        }
    }
}

// MARK: - Upload Object Sheet
struct R2UploadObjectSheetView: View {
    @ObservedObject var viewModel: R2BucketDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var objectKey = ""
    @State private var uploadMode = 0 // 0: Text, 1: File
    @State private var textContent = ""
    @State private var selectedFileData: Data?
    @State private var selectedFileName: String?
    @State private var showingFileImporter = false
    @State private var isUploading = false
    @State private var errorMessage: String?
    
    private var isValid: Bool {
        let cleanKey = objectKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanKey.isEmpty { return false }
        if uploadMode == 0 {
            return !textContent.isEmpty
        } else {
            return selectedFileData != nil
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Object Key"), footer: Text("Enter the storage path/name (e.g. data.json or images/avatar.png).")) {
                    TextField("example.txt", text: $objectKey)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                
                Section(header: Text("Upload Source")) {
                    Picker("Source", selection: $uploadMode) {
                        Text("Text / JSON Content").tag(0)
                        Text("Local File").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: uploadMode) { _ in
                        HapticManager.impact(.light)
                    }
                }
                
                if uploadMode == 0 {
                    Section(header: Text("Content")) {
                        TextEditor(text: $textContent)
                            .frame(minHeight: 140)
                            .font(.body.monospaced())
                    }
                } else {
                    Section(header: Text("Select File")) {
                        if let name = selectedFileName, let data = selectedFileData {
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundStyle(.blue)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading) {
                                    Text(name).font(.body)
                                    Text(formatBytes(data.count)).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Change") {
                                    showingFileImporter = true
                                }
                                .font(.caption)
                            }
                        } else {
                            Button {
                                showingFileImporter = true
                            } label: {
                                Label("Choose File from Device", systemImage: "arrow.up.doc")
                            }
                        }
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
            .navigationTitle("Upload Object")
            .navigationBarTitleDisplayMode(.inline)
            .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.item]) { result in
                switch result {
                case .success(let url):
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        if let data = try? Data(contentsOf: url) {
                            selectedFileData = data
                            selectedFileName = url.lastPathComponent
                            if objectKey.isEmpty {
                                objectKey = url.lastPathComponent
                            }
                        }
                    }
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Upload Object")
            .navigationBarTitleDisplayMode(.inline)
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
                                let key = objectKey.trimmingCharacters(in: .whitespacesAndNewlines)
                                let uploadData: Data
                                if uploadMode == 0 {
                                    uploadData = textContent.data(using: .utf8) ?? Data()
                                } else {
                                    uploadData = selectedFileData ?? Data()
                                }
                                try await viewModel.uploadObject(key: key, data: uploadData)
                                HapticManager.impact(.medium)
                                ToastManager.shared.showSuccess("Object Uploaded", message: key)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isUploading = false
                        }
                    }
                    .disabled(!isValid || isUploading)
                }
            }
            .interactiveDismissDisabled(isUploading)
            .toastContainer()
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Object Detail Sheet
struct R2ObjectDetailSheetView: View {
    @ObservedObject var viewModel: R2BucketDetailViewModel
    let object: R2Object
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Object Information")) {
                    HStack {
                        Text("Key")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(object.key)
                            .font(.body.monospaced())
                            .foregroundStyle(.primary)
                    }
                    
                    HStack {
                        Text("Size")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(object.formattedSize)
                            .foregroundStyle(.primary)
                    }
                    
                    if let etag = object.etag {
                        HStack {
                            Text("ETag")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(etag)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if let uploaded = object.uploaded {
                        HStack {
                            Text("Uploaded")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(DateFormatters.formatISO8601ToDisplay(uploaded, style: DateFormatters.mediumDateTime))
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                    }
                }
                
                Section {
                    Button {
                        UIPasteboard.general.string = object.key
                        HapticManager.notification(.success)
                        ToastManager.shared.showCopied("Object key copied")
                    } label: {
                        Label("Copy Key", systemImage: "doc.on.doc")
                    }
                    
                    Button(role: .destructive) {
                        HapticManager.impact(.medium)
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Object", systemImage: "trash")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Object Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Delete Object", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
                Button("Delete '\(object.key)'", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteObject(key: object.key)
                            ToastManager.shared.showSuccess("Object Deleted", message: object.key)
                            dismiss()
                        } catch {
                            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete '\(object.key)'? This action cannot be undone.")
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
                .accessibilityHidden(true)
            
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
                        Text(DateFormatters.formatISO8601ToDisplay(up, style: DateFormatters.dateOnly))
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
                HapticManager.notification(.success)
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
