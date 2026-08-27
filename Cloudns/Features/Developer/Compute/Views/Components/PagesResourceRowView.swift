import SwiftUI

// MARK: - PagesResourceRowView

struct PagesResourceRowView: View {
    // MARK: - Properties
    let name: String
    let targetId: String?
    let type: String // "kv" | "d1" | "r2" | "ai"
    let onUnbind: () -> Void
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.body)
                .foregroundStyle(themeColor)
                .frame(width: 32, height: 32)
                .background(themeColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.body.monospaced().weight(.semibold))
                    .foregroundStyle(.primary)
                
                if let targetId = targetId, !targetId.isEmpty {
                    Text(targetId)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Spacer()
            
            CloudnsBadge(.custom(color: themeColor, text: badgeTitle), isCompact: true)
        }
        .padding(.vertical, 2)
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
            copyToClipboard(name, toast: "Binding name copied")
        } label: {
            Label("Copy Binding Name", systemImage: "doc.on.doc")
        }
        
        if let targetId = targetId, !targetId.isEmpty {
            Button {
                copyToClipboard(targetId, toast: "Target ID copied")
            } label: {
                Label("Copy Target ID", systemImage: "number")
            }
        }
        
        Button(role: .destructive, action: onUnbind) {
            Label("Unbind Resource", systemImage: "trash")
        }
    }
    
    // MARK: - Actions & Helpers
    private var iconName: String {
        switch type.lowercased() {
        case "kv": return "key.fill"
        case "d1": return "cylinder.split.1x2.fill"
        case "r2": return "externaldrive.fill"
        case "ai": return "brain.head.profile"
        default: return "shippingbox.fill"
        }
    }
    
    private var themeColor: Color {
        switch type.lowercased() {
        case "kv": return .purple
        case "d1": return .indigo
        case "r2": return .blue
        case "ai": return .pink
        default: return .orange
        }
    }
    
    private var badgeTitle: String {
        type.uppercased()
    }
    
    private func copyToClipboard(_ text: String, toast: String) {
        UIPasteboard.general.string = text
        HapticManager.notification(.success)
        CloudnsToastManager.shared.showCopied(toast)
    }
}
