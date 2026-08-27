import SwiftUI

// MARK: - WorkerResourceRowView

struct WorkerResourceRowView: View {
    // MARK: - Properties
    let binding: WorkerBinding
    let onUnbind: () -> Void
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: WorkerBindingHelper.icon(for: binding.type))
                .font(.body)
                .foregroundStyle(WorkerBindingHelper.color(for: binding.type))
                .frame(width: 32, height: 32)
                .background(WorkerBindingHelper.color(for: binding.type).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(binding.name)
                    .font(.body.monospaced().weight(.semibold))
                    .foregroundStyle(.primary)
                
                if let extra = targetExtraText {
                    Text(extra)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Spacer()
            
            CloudnsBadge(
                .custom(
                    color: WorkerBindingHelper.color(for: binding.type),
                    text: WorkerBindingHelper.badgeTitle(for: binding.type)
                ),
                isCompact: true
            )
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .contextMenu {
            contextMenuItems
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onUnbind) {
                Label("Unbind", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Private Views
    @ViewBuilder
    private var contextMenuItems: some View {
        Button {
            copyToClipboard(binding.name, toast: "Binding variable copied")
        } label: {
            Label("Copy Variable Name", systemImage: "doc.on.doc")
        }
        
        if let extra = targetExtraText {
            Button {
                copyToClipboard(extra, toast: "Target ID copied")
            } label: {
                Label("Copy Target Resource ID", systemImage: "number")
            }
        }
        
        Button(role: .destructive, action: onUnbind) {
            Label("Unbind Resource", systemImage: "trash")
        }
    }
    
    // MARK: - Actions
    private var targetExtraText: String? {
        binding.namespaceId ?? binding.bucketName ?? binding.databaseId ?? binding.service ?? binding.queueName
    }
    
    private func copyToClipboard(_ text: String, toast: String) {
        UIPasteboard.general.string = text
        HapticManager.notification(.success)
        CloudnsToastManager.shared.showCopied(toast)
    }
}
