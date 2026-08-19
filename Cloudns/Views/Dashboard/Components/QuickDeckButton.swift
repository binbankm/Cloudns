import SwiftUI

// MARK: - QuickDeckButton

struct QuickDeckButton: View {
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    
    init(icon: String, color: Color, title: LocalizedStringKey) {
        self.icon = icon
        self.color = color
        self.title = title
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
            }
            .accessibilityHidden(true)
            
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(width: 82)
        .padding(.vertical, 10)
        .cloudnsCard(style: .frosted, cornerRadius: 14)
    }
}
