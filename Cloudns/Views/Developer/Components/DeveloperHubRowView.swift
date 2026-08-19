import SwiftUI

// MARK: - DeveloperHubRowView

struct DeveloperHubRowView: View {
    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    
    init(
        icon: String,
        iconColor: Color,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }
}
