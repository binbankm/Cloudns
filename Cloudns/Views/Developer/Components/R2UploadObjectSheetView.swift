import SwiftUI
import UniformTypeIdentifiers

// MARK: - R2UploadObjectSheetView

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
