import SwiftUI

// MARK: - R2ObjectDetailSheetView

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
                    
                    LabeledContent("Size", value: object.formattedSize)
                    
                    if let etag = object.etag {
                        LabeledContent {
                            Text(etag)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        } label: {
                            Text("ETag")
                        }
                    }
                    
                    if let uploaded = object.uploaded {
                        LabeledContent {
                            Text(DateFormatters.formatISO8601ToDisplay(uploaded, style: DateFormatters.mediumDateTime))
                                .font(.body.monospacedDigit())
                        } label: {
                            Text("Uploaded")
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
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
