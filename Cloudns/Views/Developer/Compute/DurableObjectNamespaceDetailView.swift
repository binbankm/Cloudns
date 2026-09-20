import SwiftUI

// MARK: - DurableObjectNamespaceDetailView

// Apple HIG Compliant Cloudflare Durable Objects Namespace Detail & Instance Inspector

struct DurableObjectNamespaceDetailView: View {
    let accountId: String
    let namespace: DurableObjectNamespace

    @State private var objects: [DurableObjectInstance] = []
    @State private var stats: DurableObjectStats?
    @State private var nextCursor: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var instanceToDelete: DurableObjectInstance?
    @State private var showingDeleteConfirm = false

    var body: some View {
        List {
            Section(header: Text("Namespace Details")) {
                LabeledContent("Namespace ID") {
                    Text(namespace.id)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
                .contextMenu {
                    Button {
                        copyToClipboard(namespace.id, toast: "Namespace ID Copied")
                    } label: {
                        Label("Copy Namespace ID", systemImage: "doc.on.doc")
                    }
                }

                if let scr = namespace.script {
                    LabeledContent("Bound Worker Script") {
                        Text(scr)
                            .font(.subheadline.monospaced())
                    }
                }

                if let cls = namespace.class {
                    HStack {
                        Text("Exported Class")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(cls)
                            .font(.subheadline)
                    }
                }
            }

            if let s = stats {
                Section(header: Text("Storage Statistics")) {
                    if let cnt = s.objectCount {
                        LabeledContent("Object Count", value: "\(cnt)")
                    }

                    if let bytes = s.storageBytes {
                        LabeledContent("Persistent Storage Size") {
                            Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
                                .font(.body.monospacedDigit())
                        }
                    }
                }
            }

            Section(header: Text("Active Instances (\(objects.count))"), footer: Text("Instances are spun up on-demand at the edge nearest to incoming coordination requests.")) {
                if isLoading, objects.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView("Loading instances…")
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } else if let err = errorMessage, objects.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(verbatim: err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } else if objects.isEmpty {
                    Text("No active instances discovered in this namespace.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(objects) { obj in
                        instanceRow(obj)
                            .contextMenu {
                                Button {
                                    copyToClipboard(obj.id, toast: "Instance ID Copied")
                                } label: {
                                    Label("Copy Instance ID", systemImage: "doc.on.doc")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    instanceToDelete = obj
                                    showingDeleteConfirm = true
                                    HapticManager.impact(.medium)
                                } label: {
                                    Label("Delete Instance", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    instanceToDelete = obj
                                    showingDeleteConfirm = true
                                    HapticManager.impact(.medium)
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
        .navigationTitle(namespace.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete Durable Object Instance", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            if let obj = instanceToDelete {
                Button("Delete Instance '\(obj.id)'", role: .destructive) {
                    Task {
                        do {
                            try await DurableObjectService.shared.deleteDOObject(accountId: accountId, namespaceId: namespace.id, objectId: obj.id)
                            objects.removeAll(where: { $0.id == obj.id })
                            ToastManager.shared.showSuccess("Instance Deleted", icon: "trash.fill")
                            HapticManager.notification(.success)
                        } catch {
                            ToastManager.shared.showError("Failed to Delete Instance")
                            HapticManager.notification(.error)
                        }
                        instanceToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                instanceToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this Durable Object instance and purge its stored state?")
        }
        .refreshable {
            await loadData()
        }
        .task {
            await loadData()
        }
    }

    private func instanceRow(_ obj: DurableObjectInstance) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.circle.fill")
                .foregroundStyle(obj.hasStoredData == true ? .green : .secondary)
                .font(.caption)
                .accessibilityHidden(true)

            Text(obj.id)
                .font(.caption.monospaced())
                .foregroundStyle(.primary)

            Spacer()

            if obj.hasStoredData == true {
                Text("Persistent Data")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.green.opacity(0.12)))
            }
        }
        .padding(.vertical, 2)
    }

    @MainActor
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            let res = try await DurableObjectService.shared.listDOObjects(accountId: accountId, namespaceId: namespace.id)
            objects = res.items
            nextCursor = res.cursor
        } catch {
            errorMessage = error.localizedDescription
        }

        stats = try? await DurableObjectService.shared.getNamespaceStats(accountId: accountId, namespaceId: namespace.id)
        isLoading = false
    }
}
