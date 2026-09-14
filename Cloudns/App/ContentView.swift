import SwiftUI

struct ContentView: View {
    @ObservedObject private var accountManager = AccountManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // MARK: - Welcome & Brand Header
                VStack(spacing: 8) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(GentleColor.accent)

                    Text("Cloudns")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(GentleColor.textPrimary)

                    Text("Design System & Infrastructure Ready")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(GentleColor.textSecondary)
                }
                .padding(.top, 20)

                // MARK: - Status Card Preview
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Core System Status")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(GentleColor.textPrimary)

                        Spacer()

                        GentleBadge("Active", iconName: "checkmark", type: .active)
                    }

                    Divider()
                        .overlay(GentleColor.textSecondary.opacity(0.15))

                    HStack(spacing: 12) {
                        GentleBadge("Proxied", iconName: "cloud.fill", type: .proxied)
                        GentleBadge("Global Key", iconName: "key.fill", type: .custom(color: GentleColor.accent))
                        GentleBadge("iOS 16+", iconName: "applelogo", type: .warning)
                    }

                    if let current = accountManager.currentAccount {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundStyle(GentleColor.accent)
                            Text(current.name)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(GentleColor.textPrimary)
                            Text("(\(current.email))")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(GentleColor.textSecondary)
                        }
                        .padding(.top, 4)
                    } else {
                        Text("No active account · Ready for login & authentication flow")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(GentleColor.textTertiary)
                            .padding(.top, 4)
                    }
                }
                .gentleCardStyle(cornerRadius: 22, padding: 18)

                Spacer()
            }
            .padding(.horizontal, 20)
            .gentleCanvas()
            .navigationBarTitleDisplayMode(.inline)
        }
        .gentleBannerOverlay()
    }
}

#Preview {
    ContentView()
}
