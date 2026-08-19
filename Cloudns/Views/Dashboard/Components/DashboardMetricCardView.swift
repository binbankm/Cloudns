import SwiftUI

// MARK: - DashboardMetricCardView

struct DashboardMetricCardView: View {
    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
    let value: String
    let subtitle: LocalizedStringKey
    let badge: LocalizedStringKey
    
    init(
        icon: String,
        iconColor: Color,
        title: LocalizedStringKey,
        value: String,
        subtitle: LocalizedStringKey,
        badge: LocalizedStringKey
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.badge = badge
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(iconColor)
                }
                .accessibilityHidden(true)
                
                Spacer()
                
                Text(badge)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            
            CloudnsRollingNumber(
                value: value,
                font: .system(.title2, design: .rounded),
                weight: .bold,
                color: .primary
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 136)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
}
