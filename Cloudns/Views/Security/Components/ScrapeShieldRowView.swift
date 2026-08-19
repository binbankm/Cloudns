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
        HStack(spacing: 16) {
            ZStack {
                iconColor.opacity(0.15)
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.body)
            }
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 8))
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
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .disabled(isLoading)
        }
        .padding(.vertical, 8)
    }
}
