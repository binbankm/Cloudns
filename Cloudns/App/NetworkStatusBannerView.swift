import SwiftUI

/// 离线状态顶部提示胶囊横幅
struct NetworkStatusBannerView: View {
    var body: some View {
        HStack(spacing: CloudnsSpacing.sm) {
            Image(systemName: "wifi.slash")
                .font(.caption.weight(.bold))
            Text("Offline Mode · Showing Cached Data")
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, CloudnsSpacing.mdMedium)
        .padding(.vertical, CloudnsSpacing.sm)
        .background(Capsule().fill(CloudnsColor.brandAccent.opacity(0.92)))
        .cloudnsShadow(.card)
        .padding(.top, CloudnsSpacing.xs)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
