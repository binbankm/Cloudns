import SwiftUI

// MARK: - Root Content Container (AGENTS.md MVVM Flow)

struct ContentView: View {
    @ObservedObject private var accountManager = AccountManager.shared

    var body: some View {
        Group {
            if accountManager.currentAccount != nil {
                ZonesListView()
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(GentleAnimation.spring, value: accountManager.hasActiveAccount)
        .gentleBannerOverlay()
    }
}

#Preview {
    ContentView()
}
