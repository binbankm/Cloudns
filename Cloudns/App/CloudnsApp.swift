import SwiftUI

@main
struct CloudnsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var themeManager = ThemeManager.shared

    init() {
        _ = AccountManager.shared
        NetworkPreheater.warmup()

        // MARK: - Global Apple HIG Pure Chevron Navigation Bar

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance

        UIViewController.configureGlobalMinimalBackButton()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(themeManager.accentColor)
        }
    }
}
