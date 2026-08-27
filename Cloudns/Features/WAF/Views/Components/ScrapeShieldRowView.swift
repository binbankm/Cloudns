import SwiftUI

// MARK: - ScrapeShieldRowView

struct ScrapeShieldRowView: View {
    // MARK: - Properties
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool
    let isLoading: Bool
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: CloudnsSpacing.md) {
            ZStack {
                iconColor.opacity(0.15)
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.body)
            }
            .frame(width: CloudnsSize.iconHero, height: CloudnsSize.iconHero)
            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Toggle(isOn: $isOn) { }
                .labelsHidden()
                .disabled(isLoading)
        }
        .padding(.vertical, CloudnsSpacing.sm)
    }
}
