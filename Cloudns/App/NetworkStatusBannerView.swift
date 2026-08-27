import SwiftUI

/// 离线状态顶部提示胶囊横幅
struct NetworkStatusBannerView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.slash")
                .font(.caption.weight(.bold))
            Text("Offline Mode · Showing Cached Data")
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.orange.opacity(0.92)))
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 3)
        .padding(.top, 4)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
