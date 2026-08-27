import SwiftUI

// MARK: - AuditLogRowView

struct AuditLogRowView: View {
    let log: AuditLog
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(log.actionColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: log.actionIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(log.actionColor)
            }
            .accessibilityHidden(true)
            .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(LocalizedStringKey(log.displayActionKey))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text(LocalizedStringKey(log.friendlyResourceTypeKey))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    if let res = log.action?.result {
                        CloudnsBadge(res ? .active("Success") : .error("Failed"), isCompact: true)
                    }
                }
                
                log.primarySummaryView
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                log.secondaryContextView
                
                HStack(spacing: 8) {
                    if let email = log.actor?.email, !email.isEmpty {
                        Label(email, systemImage: "person.circle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else if let actorType = log.actor?.type {
                        Text(actorType.uppercased())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let ip = log.actor?.ip, !ip.isEmpty {
                        Text("• \(ip)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if let when = log.when {
                        Text(DateFormatters.formatISO8601ToDisplay(when, style: DateFormatters.mediumDateTime))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
