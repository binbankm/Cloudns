import SwiftUI

// MARK: - ScrapeShieldRowView

struct ScrapeShieldRowView: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        .padding(.vertical, 8)
    }
}
