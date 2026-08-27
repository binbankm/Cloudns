import SwiftUI

// MARK: - DNS Answer Row View

struct DNSAnswerRowView: View {
    // MARK: - Properties
    let item: DNSAnswerItem
    
    // MARK: - Body
    var body: some View {
        HStack(alignment: .center, spacing: CloudnsSpacing.smMd) {
            Text(item.typeName)
                .font(.caption.weight(.bold))
                .foregroundStyle(CloudnsColor.brand)
                .padding(.horizontal, CloudnsSpacing.sm)
                .padding(.vertical, CloudnsSpacing.xxs)
                .background(CloudnsColor.brandMuted)
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.xs))
            
            VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
                Text(item.data)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text("\(item.name) • TTL \(item.ttl)s")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                UIPasteboard.general.string = item.data
                HapticManager.notification(.success)
                CloudnsToastManager.shared.showCopied("Record content copied")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, CloudnsSpacing.xs)
    }
}
