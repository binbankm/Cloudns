import SwiftUI

// MARK: - SettingsRowView

struct SettingsRowView: View {
    // MARK: - Properties
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    
    init(icon: String, color: Color, title: LocalizedStringKey) {
        self.icon = icon
        self.color = color
        self.title = title
    }
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: CloudnsSpacing.mdSmall) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: CloudnsSize.avatarSmall, height: CloudnsSize.avatarSmall)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm, style: .continuous))
                .accessibilityHidden(true)
            
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }
}
