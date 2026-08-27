import SwiftUI

// MARK: - R2ObjectRowView

struct R2ObjectRowView: View {
    // MARK: - Properties
    let object: R2Object
    
    // MARK: - Body
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: fileIcon(for: object.key))
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(object.key)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    Text(object.formattedSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let up = object.uploaded {
                        Text(DateFormatters.formatISO8601ToDisplay(up, style: DateFormatters.dateOnly))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                UIPasteboard.general.string = object.key
                HapticManager.notification(.success)
                CloudnsToastManager.shared.showCopied("Object key copied")
            } label: {
                Label("Copy Object Key", systemImage: "doc.on.doc")
            }
        }
    }
    
    // MARK: - Actions
    private func fileIcon(for key: String) -> String {
        let lower = key.lowercased()
        if lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".webp") || lower.hasSuffix(".svg") {
            return "photo.fill"
        } else if lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") || lower.hasSuffix(".webm") {
            return "film.fill"
        } else if lower.hasSuffix(".json") || lower.hasSuffix(".js") || lower.hasSuffix(".ts") || lower.hasSuffix(".html") || lower.hasSuffix(".css") {
            return "chevron.left.forwardslash.chevron.right"
        } else if lower.hasSuffix(".zip") || lower.hasSuffix(".tar") || lower.hasSuffix(".gz") {
            return "archivebox.fill"
        }
        return "doc.fill"
    }
}
