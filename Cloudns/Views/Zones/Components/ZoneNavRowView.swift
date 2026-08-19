import SwiftUI

// MARK: - ZoneNavRowView

struct ZoneNavRowView<Destination: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let color: Color
    let destination: Destination

    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        icon: String,
        color: Color,
        destination: Destination
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.destination = destination
    }

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.12))
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
}
