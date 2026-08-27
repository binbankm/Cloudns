import SwiftUI

// MARK: - RootView

struct RootView: View {
    // MARK: - Properties
    
    @AppStorage(AppStorageKey.isLoggedIn) private var isLoggedIn = false
    @AppStorage(AppStorageKey.hasSeenOnboarding) private var hasSeenOnboarding = false
    @AppStorage(AppStorageKey.isAppLockEnabled) private var isAppLockEnabled = false
    @AppStorage(AppStorageKey.themePreference) private var themePreference = "system"
    @AppStorage(AppStorageKey.appLanguage) private var appLanguage = "system"
    @State private var selectedTab: AppTab = .dashboard
    @State private var tabViewResetId = UUID()
    @ObservedObject private var authManager = AppAuthManager.shared
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @Environment(\.scenePhase) private var scenePhase
    
    @ObservedObject private var router = DeepLinkRouter.shared
    
    var currentLocale: Locale {
        if appLanguage == "system" {
            return Locale.autoupdatingCurrent
        }
        return Locale(identifier: appLanguage)
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if isLoggedIn {
                TabView(selection: $selectedTab) {
                    DashboardView()
                        .tabItem {
                            Label("Dashboard", systemImage: selectedTab == .dashboard ? "square.grid.2x2.fill" : "square.grid.2x2")
                        }
                        .tag(AppTab.dashboard)
                    
                    ZonesListView()
                        .tabItem {
                            Label("Domains", systemImage: selectedTab == .domains ? "globe.asia.australia.fill" : "globe.asia.australia")
                        }
                        .tag(AppTab.domains)
                    
                    DeveloperHubView()
                        .tabItem {
                            Label("Developer", systemImage: selectedTab == .developer ? "cpu.fill" : "cpu")
                        }
                        .tag(AppTab.developer)
                    
                    DevToolsHubView()
                        .tabItem {
                            Label("Dev Tools", systemImage: selectedTab == .devtools ? "wrench.and.screwdriver.fill" : "wrench.and.screwdriver")
                        }
                        .tag(AppTab.devtools)
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: selectedTab == .settings ? "gearshape.fill" : "gearshape")
                        }
                        .tag(AppTab.settings)
                }
                .id(tabViewResetId)
                .onReceive(NotificationCenter.default.publisher(for: .localCachePurged)) { _ in
                    tabViewResetId = UUID()
                }
                .onReceive(NotificationCenter.default.publisher(for: .accountSwitched)) { _ in
                    router.activeDestination = nil
                    tabViewResetId = UUID()
                }
                .cloudnsSensorySelection(trigger: selectedTab)
                .overlay(alignment: .top) {
                    if !networkMonitor.isConnected {
                        NetworkStatusBannerView()
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: networkMonitor.isConnected)
                .overlay {
                    if isAppLockEnabled {
                        AppLockOverlayView(authManager: authManager, scenePhase: scenePhase)
                    }
                }
            } else {
                LoginView()
            }
        }
        .animation(.default, value: isLoggedIn)
        .animation(.default, value: hasSeenOnboarding)
        .environment(\.locale, currentLocale)
        .toastContainer()
        .preferredColorScheme(themePreference == "light" ? .light : (themePreference == "dark" ? .dark : nil))
        .id(appLanguage)
        .onAppear {
            _ = AccountManager.shared
            WidgetDataStore.shared.notifyWidgetsToReload()
            if isAppLockEnabled && !authManager.isUnlocked {
                authManager.authenticate()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                NotificationCenter.default.post(name: .appWillEnterForeground, object: nil)
                authManager.handleAppWillEnterForeground()
            } else if newPhase == .background {
                authManager.handleAppDidEnterBackground()
            }
        }
        .onOpenURL { url in
            DeepLinkRouter.shared.handle(url: url, currentTab: $selectedTab)
        }
        .sheet(item: $router.activeDestination) { dest in
            NavigationStack {
                switch dest {
                case .dig:
                    DNSDigToolView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { router.activeDestination = nil }
                            }
                        }
                case .trace:
                    CFTraceToolView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { router.activeDestination = nil }
                            }
                        }
                case .status:
                    CloudflareStatusView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { router.activeDestination = nil }
                            }
                        }
                case .ipranges:
                    CFIpRangesToolView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { router.activeDestination = nil }
                            }
                        }
                case .zone(let id):
                    ZoneDetailDeepLinkWrapper(zoneId: id) {
                        router.activeDestination = nil
                    }
                case .worker(let id):
                    WorkerDetailDeepLinkWrapper(workerId: id) {
                        router.activeDestination = nil
                    }
                case .pages(let id):
                    PagesDetailDeepLinkWrapper(projectId: id) {
                        router.activeDestination = nil
                    }
                }
            }
            .environment(\.locale, currentLocale)
        }
    }
}

typealias ContentView = RootView

// MARK: - Preview

#Preview {
    RootView()
}
