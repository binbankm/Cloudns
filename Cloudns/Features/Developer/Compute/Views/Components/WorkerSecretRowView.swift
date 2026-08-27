import SwiftUI

// MARK: - WorkerSecretRowView

struct WorkerSecretRowView: View {
    // MARK: - Properties
    let secret: WorkerSecret
    let onDelete: () -> Void
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: CloudnsSpacing.mdSmall) {
            Image(systemName: "key.fill")
                .font(.body)
                .foregroundStyle(CloudnsColor.brandAccent)
                .frame(width: CloudnsSize.controlHeightSmall, height: CloudnsSize.controlHeightSmall)
                .background(CloudnsColor.warningMuted)
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(secret.name)
                    .font(.body.monospaced().weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text("•••••••••••• (Encrypted)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            CloudnsBadge(.proxied("SECRET"), isCompact: true)
        }
        .padding(.vertical, CloudnsSpacing.xxs)
        .contentShape(Rectangle())
        .contextMenu {
            contextMenuItems
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Private Views
    @ViewBuilder
    private var contextMenuItems: some View {
        Button {
            copyToClipboard(secret.name, toast: "Secret name copied")
        } label: {
            Label("Copy Secret Name", systemImage: "doc.on.doc")
        }
        
        Button(role: .destructive, action: onDelete) {
            Label("Delete Secret", systemImage: "trash")
        }
    }
    
    // MARK: - Actions
    private func copyToClipboard(_ text: String, toast: String) {
        UIPasteboard.general.string = text
        HapticManager.notification(.success)
        CloudnsToastManager.shared.showCopied(toast)
    }
}
