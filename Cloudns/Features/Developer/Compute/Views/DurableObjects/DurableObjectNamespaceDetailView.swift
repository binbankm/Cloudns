import SwiftUI

// MARK: - DurableObjectNamespaceDetailView

struct DurableObjectNamespaceDetailView: View {
    // MARK: - Properties
    let accountId: String
    let namespace: DurableObjectNamespace
    
    @State private var objects: [DurableObjectInstance] = []
    @State private var nextCursor: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // MARK: - Body
    var body: some View {
        List {
            Section(header: Text("Namespace Details")) {
                HStack {
                    Text("Namespace ID")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(namespace.id)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
                
                if let scr = namespace.script {
                    HStack {
                        Text("Bound Worker Script")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(scr)
                            .font(.subheadline.monospaced())
                    }
                }
                
                if let cls = namespace.class {
                    HStack {
                        Text("Exported Class")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(cls)
                            .font(.subheadline)
                    }
                }
            }
            
            Section(header: Text("Active Instances (\(objects.count))"), footer: Text("Instances are spun up on-demand at the edge nearest to incoming coordination requests.")) {
                if isLoading && objects.isEmpty {
                    ForEach(DurableObjectInstance.placeholders) { placeholder in
                        instanceRow(placeholder)
                    }
                    .skeletonLoading(true)
                } else if let err = errorMessage, objects.isEmpty {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if objects.isEmpty {
                    Text("No active instances discovered in this namespace.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(objects) { obj in
                        instanceRow(obj)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
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
    // MARK: - Private Views
    private func instanceRow(_ obj: DurableObjectInstance) -> some View {
        HStack {
            Image(systemName: "circle.circle.fill")
                .foregroundStyle(obj.hasStoredData == true ? .green : .secondary)
                .font(.caption)
                .accessibilityHidden(true)
            
            Text(obj.id)
                .font(.caption.monospaced())
                .foregroundStyle(.primary)
            
            Spacer()
            
            if obj.hasStoredData == true {
                CloudnsBadge(.active("Persistent Data"), isCompact: true)
            }
        }
        .padding(.vertical, CloudnsSpacing.xxs)
    }
    
    // MARK: - Actions
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
