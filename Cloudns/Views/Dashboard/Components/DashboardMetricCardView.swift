import SwiftUI

// MARK: - DashboardMetricCardView (Compact & Non-wrapping)

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
        VStack(alignment: .leading, spacing: 0) {
            // 1. Top Bar: Left Icon + Right Tag Badge
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.14))
                        .frame(width: 26, height: 26)
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(iconColor)
                }
                .accessibilityHidden(true)
                
                Spacer()
                
                Text(badge)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
                    .lineLimit(1)
            }
            
            Spacer(minLength: 4)
            
            // 2. Middle Value: Large Bold Number
            Text(value)
                .font(Font.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.80)
            
            Spacer(minLength: 4)
            
            // 3. Bottom Text Group: Title (Full width line) & Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.80)
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, minHeight: 114, maxHeight: 114, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
