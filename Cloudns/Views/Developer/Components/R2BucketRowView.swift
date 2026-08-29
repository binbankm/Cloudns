import SwiftUI

// MARK: - R2BucketRowView

struct R2BucketRowView: View {
    let bucket: R2Bucket
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "externaldrive.fill")
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(bucket.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 10) {
                    if let loc = bucket.location, !loc.isEmpty {
                        Text(loc.uppercased())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let date = bucket.creationDate {
                        Text(DateFormatters.formatISO8601ToDisplay(date, style: DateFormatters.dateOnly))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            CloudnsBadge(.custom(color: .secondary, text: "S3 Compatible"), isCompact: true)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                UIPasteboard.general.string = bucket.name
                HapticManager.impact(.light)
                ToastManager.shared.showCopied("Bucket name copied")
            } label: {
                Label("Copy Bucket Name", systemImage: "doc.on.doc")
            }
        }
    }
}
