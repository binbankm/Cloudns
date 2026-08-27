import SwiftUI

// MARK: - TunnelRowView

struct TunnelRowView: View {
    // MARK: - Properties
    let tunnel: CFTunnel
    
    var isHealthy: Bool {
        tunnel.isHealthy
    }
    
    // MARK: - Body
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "network")
                .font(.body)
                .foregroundStyle(isHealthy ? .green : .red)
                .frame(width: 32, height: 32)
                .background((isHealthy ? Color.green : Color.red).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(tunnel.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    CloudnsBadge(
                        isHealthy ? .active((tunnel.status ?? "Healthy").capitalized) : .error((tunnel.status ?? "Inactive").capitalized),
                        isCompact: true
                    )
                }
                
                Text(tunnel.id)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if let count = tunnel.connections?.count {
                Text("\(count) Connectors")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                UIPasteboard.general.string = tunnel.id
                HapticManager.impact(.light)
                CloudnsToastManager.shared.showCopied("Tunnel ID copied")
            } label: {
                Label("Copy Tunnel UUID", systemImage: "doc.on.doc")
            }
        }
    }
}
