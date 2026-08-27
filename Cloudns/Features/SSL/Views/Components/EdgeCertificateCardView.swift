import SwiftUI

// MARK: - EdgeCertificateCardView

struct EdgeCertificateCardView: View {
    // MARK: - Properties
    let certificate: EdgeCertificateModel
    
    var iconName: String {
        switch certificate.type.lowercased() {
        case "universal": return "globe"
        case "advanced": return "star.fill"
        case "custom": return "person.badge.key"
        default: return "seal.fill"
        }
    }
    
    var iconColor: Color {
        switch certificate.type.lowercased() {
        case "universal": return .blue
        case "advanced": return .purple
        case "custom": return .orange
        default: return .gray
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            HStack {
                ZStack {
                    iconColor.opacity(0.15)
                    Image(systemName: iconName)
                        .foregroundStyle(iconColor)
                        .font(.body)
                        .accessibilityHidden(true)
                }
                .frame(width: CloudnsSize.avatarSmall, height: CloudnsSize.avatarSmall)
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                
                Text(certificate.type.capitalized)
                    .font(.body.weight(.medium))
                
                if certificate.type.lowercased() == "universal" {
                    CloudnsBadge(.free, isCompact: true)
                } else if certificate.type.lowercased() == "advanced" {
                    CloudnsBadge(.addOn, isCompact: true)
                } else if certificate.type.lowercased() == "custom" {
                    CloudnsBadge(.business, isCompact: true)
                }
                
                Spacer()
                
                CloudnsBadge(certificate.status.lowercased() == "active" ? .active("Active") : .custom(color: .secondary, text: certificate.status.capitalized), isCompact: true)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
                HStack(alignment: .top) {
                    Text("Hosts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                        ForEach(certificate.hosts, id: \.self) { host in
                            Text(host)
                                .font(.subheadline)
                        }
                    }
                }
                
                HStack {
                    Text("Issuer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .leading)
                    Text(certificate.issuer)
                        .font(.subheadline)
                }
                
                HStack {
                    Text("Signature")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .leading)
                    Text(certificate.signature)
                        .font(.subheadline.monospacedDigit())
                }
                    
                HStack {
                    Text(certificate.id)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Text(formatDate(certificate.expiresOn))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(CloudnsColor.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md))
        .cloudnsShadow(.card)
        .padding(.vertical, CloudnsSpacing.xs)
    }
    
    // MARK: - Actions
    private func formatDate(_ dateString: String) -> String {
        if dateString == "N/A" { return dateString }
        return DateFormatters.formatISO8601ToDisplay(dateString, style: DateFormatters.dateOnly)
    }
}
