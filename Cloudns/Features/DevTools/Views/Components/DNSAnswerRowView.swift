import SwiftUI

// MARK: - DNS Answer Row View

struct DNSAnswerRowView: View {
    // MARK: - Properties
    let item: DNSAnswerItem
    
    // MARK: - Body
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(item.typeName)
                .font(.caption.weight(.bold))
                .foregroundStyle(.blue)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            VStack(alignment: .leading, spacing: 2) {
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
        .padding(.vertical, 3)
    }
}
