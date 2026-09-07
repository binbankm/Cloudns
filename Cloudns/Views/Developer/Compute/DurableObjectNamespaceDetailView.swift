import SwiftUI

// MARK: - DurableObjectNamespaceDetailView
// Apple HIG Compliant Cloudflare Durable Objects Namespace Detail & Instance Inspector

struct DurableObjectNamespaceDetailView: View {
    let accountId: String
    let namespace: DurableObjectNamespace
    
    @State private var objects: [DurableObjectInstance] = []
    @State private var nextCursor: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
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
            
            Section(header: Text("Active Instances (\(objects.count))"), footer: Text("Instances are spun up on-demand at the edge nearest to incoming coordination requests.")) {
                if isLoading && objects.isEmpty {
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
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(namespace.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await fetchObjects()
        }
        .task {
            await fetchObjects()
        }
    }
    
    @ViewBuilder
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
    
    private func fetchObjects() async {
        isLoading = true
        errorMessage = nil
        do {
            let res = try await DurableObjectService.shared.listDOObjects(accountId: accountId, namespaceId: namespace.id)
            self.objects = res.items
            self.nextCursor = res.cursor
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
