import SwiftUI

// MARK: - WorkerVariableRowView

struct WorkerVariableRowView: View {
    // MARK: - Properties
    let variable: WorkerBinding
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "slider.horizontal.3")
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(variable.name)
                    .font(.body.monospaced().weight(.semibold))
                    .foregroundStyle(.primary)
                
                if let text = variable.text, !text.isEmpty {
                    Text(text)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            CloudnsBadge(.custom(color: .blue, text: "VARIABLE"), isCompact: true)
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
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
        if let val = variable.text {
            Button {
                copyToClipboard(val, toast: "Value copied")
            } label: {
                Label("Copy Value", systemImage: "doc.on.doc")
            }
        }
        
        Button {
            copyToClipboard(variable.name, toast: "Key copied")
        } label: {
            Label("Copy Variable Name", systemImage: "doc.on.doc")
        }
        
        Button(action: onEdit) {
            Label("Edit Variable", systemImage: "pencil")
        }
        
        Button(role: .destructive, action: onDelete) {
            Label("Delete Variable", systemImage: "trash")
        }
    }
    
    // MARK: - Actions
    private func copyToClipboard(_ text: String, toast: String) {
        UIPasteboard.general.string = text
        HapticManager.notification(.success)
        CloudnsToastManager.shared.showCopied(toast)
    }
}
