import SwiftUI

// MARK: - DeveloperHubRowView

struct DeveloperHubRowView: View {
    // MARK: - Properties
    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let badge: CloudnsBadgeType?
    
    init(
        icon: String,
        iconColor: Color,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        badge: CloudnsBadgeType? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
    }
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: CloudnsSpacing.mdMedium) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: CloudnsSize.controlHeightSmall, height: CloudnsSize.controlHeightSmall)
                .background(iconColor.opacity(0.12))
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
