import SwiftUI

// MARK: - PagesEnvVarRowView

struct PagesEnvVarRowView: View {
    // MARK: - Properties
    let name: String
    let value: PagesEnvVarValue
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    // MARK: - Body
    var body: some View {
        HStack(alignment: .center, spacing: CloudnsSpacing.mdSmall) {
            Image(systemName: value.isSecret ? "key.fill" : "slider.horizontal.3")
                .font(.body)
                .foregroundStyle(value.isSecret ? .orange : .blue)
                .frame(width: CloudnsSize.controlHeightSmall, height: CloudnsSize.controlHeightSmall)
                .background((value.isSecret ? Color.orange : Color.blue).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.body.monospaced().weight(.semibold))
                    .foregroundStyle(.primary)
                
                if value.isSecret {
                    Text("•••••••••••• (Encrypted Secret)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                } else if let val = value.value, !val.isEmpty {
                    Text(val)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if value.isSecret {
                CloudnsBadge(.proxied("SECRET"), isCompact: true)
            } else {
                CloudnsBadge(.custom(color: .blue, text: "VARIABLE"), isCompact: true)
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
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
        if !value.isSecret, let val = value.value {
            Button {
                copyToClipboard(val, toast: "Value copied")
            } label: {
                Label("Copy Value", systemImage: "doc.on.doc")
            }
        }
        
        Button {
            copyToClipboard(name, toast: value.isSecret ? "Secret name copied" : "Key name copied")
        } label: {
            Label(value.isSecret ? "Copy Secret Name" : "Copy Key Name", systemImage: "doc.on.doc")
        }
        
        if !value.isSecret {
            Button(action: onEdit) {
                Label("Edit Variable", systemImage: "pencil")
            }
        }
        
        Button(role: .destructive, action: onDelete) {
            Label(value.isSecret ? "Delete Secret" : "Delete Variable", systemImage: "trash")
        }
    }
    
    // MARK: - Actions
    private func copyToClipboard(_ text: String, toast: String) {
        UIPasteboard.general.string = text
        HapticManager.notification(.success)
        CloudnsToastManager.shared.showCopied(toast)
    }
}
