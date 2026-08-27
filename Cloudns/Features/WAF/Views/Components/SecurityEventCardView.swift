import SwiftUI

// MARK: - SecurityEventCardView

struct SecurityEventCardView: View {
    // MARK: - Properties
    let event: SecurityEvent
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.smMd) {
            HStack {
                CloudnsBadge(.custom(color: colorForAction(event.action), text: actionDisplayName(event.action)), isCompact: true)
                
                Spacer()
                
                Text(formatDate(event.datetime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                    Text("IP Address")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: CloudnsSpacing.xs) {
                        Text(countryFlag(countryCode: event.clientCountryName))
                        Text(event.clientIP)
                            .font(.subheadline.monospacedDigit())
                    }
                }
                
                Spacer()
                
                if let asn = event.clientAsn {
                    VStack(alignment: .trailing, spacing: CloudnsSpacing.xs) {
                        Text("ASN")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("AS\(asn)")
                            .font(.subheadline)
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                Text("Source / Engine")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(event.source.capitalized)
                    .font(.footnote)
            }
            
            VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                Text("Target URL")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(event.host)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(CloudnsColor.brand)
            }
        }
        .padding(.vertical, CloudnsSpacing.xs)
    }
    
    // MARK: - Actions
    private func actionDisplayName(_ action: String) -> String {
        switch action {
        case "block": return "BLOCK"
        case "challenge": return "LEGACY CAPTCHA"
        case "js_challenge": return "JS CHALLENGE"
        case "managed_challenge": return "MANAGED CHALLENGE"
        case "log": return "LOG"
        case "connectionClose": return "CONNECTION CLOSE"
        default: return action.uppercased()
        }
    }
    
    private func colorForAction(_ action: String) -> Color {
        switch action {
        case "block", "connectionClose": return .red
        case "challenge", "js_challenge", "managed_challenge": return .orange
        case "log": return .blue
        default: return .gray
        }
    }
    
    private func countryFlag(countryCode: String) -> String {
        CountryCoordinates.flag(for: countryCode)
    }
    
    private func formatDate(_ isoString: String) -> String {
        DateFormatters.formatISO8601ToDisplay(isoString, style: DateFormatters.mediumDateTime)
    }
}
