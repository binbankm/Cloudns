import SwiftUI

// MARK: - DashboardMetricCardView (Compact & Non-wrapping)

struct DashboardMetricCardView: View {
    // MARK: - Properties
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
    
    // MARK: - Body
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Top Bar: Left Icon + Right Tag Badge
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.14))
                        .frame(width: CloudnsSize.iconLarge, height: CloudnsSize.iconLarge)
                    Image(systemName: icon)
                        .font(CloudnsTypography.caption.weight(.semibold))
                        .foregroundStyle(iconColor)
                }
                .accessibilityHidden(true)
                
                Spacer()
                
                Text(badge)
                    .font(CloudnsTypography.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, CloudnsSpacing.sm)
                    .padding(.vertical, CloudnsSpacing.xxs)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
                    .lineLimit(1)
            }
            
            Spacer(minLength: CloudnsSpacing.xs)
            
            // 2. Middle Value: Large Bold Number
            CloudnsRollingNumber(
                value: value,
                font: .system(.title2, design: .rounded),
                weight: .bold,
                color: .primary
            )
            .lineLimit(1)
            .minimumScaleFactor(0.80)
            
            Spacer(minLength: CloudnsSpacing.xs)
            
            // 3. Bottom Text Group: Title (Full width line) & Subtitle
            VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
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
        .padding(CloudnsSpacing.mdSmall)
        .frame(maxWidth: .infinity, minHeight: 114, maxHeight: 114, alignment: .topLeading)
        .cloudnsCard(style: .frosted, size: .compact)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value), \(subtitle)")
    }
}
