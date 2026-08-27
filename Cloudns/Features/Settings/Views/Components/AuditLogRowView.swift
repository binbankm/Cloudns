import SwiftUI

// MARK: - AuditLogRowView

struct AuditLogRowView: View {
    // MARK: - Properties
    let log: AuditLog
    
    // MARK: - Body
    var body: some View {
        HStack(alignment: .top, spacing: CloudnsSpacing.mdSmall) {
            ZStack {
                Circle()
                    .fill(log.actionColor.opacity(0.12))
                    .frame(width: CloudnsSize.avatarMedium, height: CloudnsSize.avatarMedium)
                Image(systemName: log.actionIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(log.actionColor)
            }
            .accessibilityHidden(true)
            .padding(.top, CloudnsSpacing.xxs)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: CloudnsSpacing.sm) {
                    Text(LocalizedStringKey(log.displayActionKey))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text(LocalizedStringKey(log.friendlyResourceTypeKey))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, CloudnsSpacing.sm)
                        .padding(.vertical, CloudnsSpacing.xxs)
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
                
                HStack(spacing: CloudnsSpacing.sm) {
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
                .padding(.top, CloudnsSpacing.xs)
        }
        .padding(.vertical, CloudnsSpacing.xs)
        .contentShape(Rectangle())
    }
}
