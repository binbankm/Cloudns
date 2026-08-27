import SwiftUI

// MARK: - R2BucketRowView

struct R2BucketRowView: View {
    // MARK: - Properties
    let bucket: R2Bucket
    
    // MARK: - Body
    var body: some View {
        HStack(alignment: .center, spacing: CloudnsSpacing.mdMedium) {
            Image(systemName: "externaldrive.fill")
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: CloudnsSize.controlHeightSmall, height: CloudnsSize.controlHeightSmall)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(bucket.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                HStack(spacing: CloudnsSpacing.smMd) {
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
        .padding(.vertical, CloudnsSpacing.xs)
        .contextMenu {
            Button {
                UIPasteboard.general.string = bucket.name
                HapticManager.impact(.light)
                CloudnsToastManager.shared.showCopied("Bucket name copied")
            } label: {
                Label("Copy Bucket Name", systemImage: "doc.on.doc")
            }
        }
    }
}
