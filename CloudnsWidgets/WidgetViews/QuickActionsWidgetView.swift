import SwiftUI
import WidgetKit

// MARK: - QuickActionsWidgetView

public struct QuickActionsWidgetView: View {
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.horizontal.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                Text("Cloudns Quick Deck")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            HStack(spacing: 8) {
                actionTile(
                    title: "DoH Dig",
                    icon: "magnifyingglass",
                    color: .blue,
                    urlString: "cloudns://tools/dig"
                )
                
                actionTile(
                    title: "Trace Route",
                    icon: "point.topleft.down.curvedto.point.bottomright.up",
                    color: .purple,
                    urlString: "cloudns://tools/trace"
                )
                
                actionTile(
                    title: "CF Status",
                    icon: "cloud.fill",
                    color: .green,
                    urlString: "cloudns://tools/status"
                )
                
                actionTile(
                    title: "IP Ranges",
                    icon: "network",
                    color: .orange,
                    urlString: "cloudns://tools/ipranges"
                )
            }
        }
        .padding(12)
    }
    
    private func actionTile(title: String, icon: String, color: Color, urlString: String) -> some View {
        let destination = URL(string: urlString) ?? URL(fileURLWithPath: "/")
        return Link(destination: destination) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(color)
                }
                
                Text(LocalizedStringKey(title))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(Color(.secondarySystemFill).opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
