import SwiftUI

// MARK: - ZoneNavRowView

struct ZoneNavRowView<Destination: View>: View {
    // MARK: - Properties
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let color: Color
    let badge: CloudnsBadgeType?
    let destination: Destination

    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        icon: String,
        color: Color,
        badge: CloudnsBadgeType? = nil,
        destination: Destination
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.badge = badge
        self.destination = destination
    }

    // MARK: - Body
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: CloudnsSpacing.mdMedium) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                    .frame(width: CloudnsSize.controlHeightSmall, height: CloudnsSize.controlHeightSmall)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
                    HStack(spacing: CloudnsSpacing.sm) {
                        Text(title)
                            .font(.body)
                            .foregroundStyle(.primary)
                        
                        if let badge = badge {
                            CloudnsBadge(badge, isCompact: true)
                        }
                    }
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, CloudnsSpacing.xs)
            .accessibilityElement(children: .combine)
        }
    }
}
