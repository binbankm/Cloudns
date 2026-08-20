import SwiftUI

// MARK: - DNSRecordRowView

struct DNSRecordRowView: View {
    let record: DNSRecord
    var onToggleProxy: (() -> Void)?
    
    private var recordTypeColor: Color {
        switch record.type.uppercased() {
        case "A", "AAAA": return .blue
        case "CNAME": return .green
        case "TXT": return .purple
        case "MX": return .orange
        case "NS", "CAA", "SRV": return .teal
        default: return .indigo
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                // Record Type Badge
                Text(record.type)
                    .font(.caption.monospacedDigit().weight(.bold))
                    .frame(width: 48)
                    .padding(.vertical, 3)
                    .background(recordTypeColor.opacity(0.14))
                    .foregroundStyle(recordTypeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                
                // Record Name
                Text(record.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                // Interactive Proxy Status Badge (Click to quick toggle)
                if record.proxiable == true {
                    Button {
                        HapticManager.impact(.medium)
                        onToggleProxy?()
                    } label: {
                        CloudnsBadge(
                            record.proxied == true ? .proxied("Proxied") : .dnsOnly("DNS Only"),
                            isCompact: true
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    CloudnsBadge(.dnsOnly("DNS Only"), isCompact: true)
                }
            }
            
            HStack(alignment: .top) {
                Text(record.content ?? (record.data != nil ? "Advanced Record Data" : "No content"))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                Spacer()
                
                Text(record.ttl == 1 ? "Auto" : "\(record.ttl)s")
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            
            if let comment = record.comment, !comment.isEmpty {
                Text(comment)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.type) record \(record.name), points to \(record.content ?? ""), \(record.proxied == true ? "Proxied" : "DNS Only")")
    }
}
