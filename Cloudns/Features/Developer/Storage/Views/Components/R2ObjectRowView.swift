import SwiftUI

// MARK: - R2ObjectRowView

struct R2ObjectRowView: View {
    // MARK: - Properties
    let object: R2Object
    
    // MARK: - Body
    var body: some View {
        HStack(alignment: .center, spacing: CloudnsSpacing.mdMedium) {
            Image(systemName: fileIcon(for: object.key))
                .font(.body)
                .foregroundStyle(CloudnsColor.brand)
                .frame(width: CloudnsSize.controlHeightSmall, height: CloudnsSize.controlHeightSmall)
                .background(CloudnsColor.brandMuted)
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(object.key)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: CloudnsSpacing.smMd) {
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
        .padding(.vertical, CloudnsSpacing.xs)
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
