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
                        .font(HIGTypography.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = namespace.id
                        ToastManager.shared.showCopied("Namespace ID Copied")
                        HIGFeedback.copied()
                    } label: {
                        Label("Copy Namespace ID", systemImage: "doc.on.doc")
                    }
                }
                
                if let scr = namespace.script {
                    LabeledContent("Bound Worker Script") {
                        Text(scr)
                            .font(HIGTypography.subheadline.monospaced())
                    }
                }
                
                if let cls = namespace.class {
                    HStack {
                        Text("Exported Class")
                            .font(HIGTypography.body)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(cls)
                            .font(HIGTypography.subheadline)
                    }
                }
            }
            
            Section(header: Text("Active Instances (\(objects.count))"), footer: Text("Instances are spun up on-demand at the edge nearest to incoming coordination requests.")) {
                if isLoading && objects.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView("Loading instances…")
                            .font(HIGTypography.caption)
                        Spacer()
                    }
                    .padding(.vertical, HIGTokens.Spacing.xs)
                } else if let err = errorMessage, objects.isEmpty {
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(HIGColors.error)
                        Text(verbatim: err)
                            .font(HIGTypography.caption)
                            .foregroundStyle(HIGColors.error)
                    }
                } else if objects.isEmpty {
                    Text("No active instances discovered in this namespace.")
                        .font(HIGTypography.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(objects) { obj in
                        instanceRow(obj)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = obj.id
                                    ToastManager.shared.showCopied("Instance ID Copied")
                                    HIGFeedback.copied()
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
        HStack(spacing: HIGTokens.Spacing.sm) {
            Image(systemName: "circle.circle.fill")
                .foregroundStyle(obj.hasStoredData == true ? HIGColors.success : .secondary)
                .font(HIGTypography.caption)
                .accessibilityHidden(true)
            
            Text(obj.id)
                .font(HIGTypography.caption.monospaced())
                .foregroundStyle(.primary)
            
            Spacer()
            
            if obj.hasStoredData == true {
                HIGBadge(.active("Persistent Data"), isCompact: true)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
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
