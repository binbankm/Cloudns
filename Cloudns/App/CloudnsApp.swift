import SwiftUI

@main
struct CloudnsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        _ = AccountManager.shared
        NetworkPreheater.warmup()
        
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // MARK: - Global Apple HIG Pure Chevron Navigation Bar
        // Implements iOS 14+ minimal back button (chevron only) to eliminate
        // cross-language fallback text artifacts while preserving gestures and accessibility.
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()
        
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.clear,
            .font: UIFont.systemFont(ofSize: 0.1)
        ]
        backButtonAppearance.highlighted.titleTextAttributes = [
            .foregroundColor: UIColor.clear,
            .font: UIFont.systemFont(ofSize: 0.1)
        ]
        navBarAppearance.backButtonAppearance = backButtonAppearance
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        UIViewController.configureGlobalMinimalBackButton()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
