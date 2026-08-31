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
        // Hides back button text globally to prevent mixed-language fallback artifacts
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()
        
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        backButtonAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.clear]
        navBarAppearance.backButtonAppearance = backButtonAppearance
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Universal fallback for back button title positioning
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffset(horizontal: -1000, vertical: 0), for: .default)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
