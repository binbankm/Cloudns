import SwiftUI

// MARK: - ZoneCardView (Gentle Domain Squircle Card)

struct ZoneCardView: View {
    let zone: Zone
    let onTogglePause: () -> Void
    var onRequestDelete: (() -> Void)?

    private var statusBadgeType: GentleBadgeType {
        if zone.paused {
            return .danger
        }
        switch zone.zoneStatus {
        case .active:
            return .active
        case .pending, .initializing:
            return .warning
        case .moved, .deleted, .deactivated:
            return .danger
        default:
            return .warning
        }
    }

    private var statusBadgeTitle: String {
        if zone.paused {
            return "Paused"
        }
        return zone.zoneStatus.displayName
    }

    private var statusBadgeIcon: String {
        if zone.paused {
            return "pause.fill"
        }
        switch zone.zoneStatus {
        case .active:
            return "checkmark"
        case .pending, .initializing:
            return "clock.arrow.circlepath"
        default:
            return "exclamationmark.circle"
        }
    }
    var body: some View {
        HStack(alignment: .center, spacing: GentleSpacing.sm) {
            GentleDomainAvatar(domain: zone.name, size: .medium)

            Text(zone.name)
                .font(GentleTypography.cardTitle)
                .foregroundStyle(GentleColor.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: GentleSpacing.xs)

            GentleBadge(
                statusBadgeTitle,
                iconName: statusBadgeIcon,
                type: statusBadgeType
            )

            Image(systemName: "chevron.right")
                .font(GentleTypography.captionSmall)
                .foregroundStyle(GentleColor.textSecondary.opacity(0.4))
                .padding(.leading, GentleSpacing.xxs)
        }
        .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: GentleSpacing.md)
        .contextMenu {
            Button(role: zone.paused ? .none : .destructive) {
                GentleHaptics.warning()
                onTogglePause()
            } label: {
                Label(
                    zone.paused ? "Resume Cloudflare" : "Pause Cloudflare on Site",
                    systemImage: zone.paused ? "play.circle" : "pause.circle"
                )
            }

            if let onRequestDelete {
                Button(role: .destructive) {
                    onRequestDelete()
                } label: {
                    Label("Delete Domain", systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    ZoneCardView(
        zone: Zone(
            id: "1",
            name: "example.com",
            status: "active",
            paused: false,
            type: "full",
            plan: ZonePlan(name: "Pro"),
            nameServers: ["ns1.cloudflare.com", "ns2.cloudflare.com"]
        ),
        onTogglePause: {}
    )
    .padding()
}
