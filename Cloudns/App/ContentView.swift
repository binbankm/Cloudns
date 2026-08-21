import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    // MARK: - Properties
    
    @AppStorage(AppStorageKey.isLoggedIn) private var isLoggedIn = false
    @AppStorage(AppStorageKey.hasSeenOnboarding) private var hasSeenOnboarding = false
    @AppStorage(AppStorageKey.isAppLockEnabled) private var isAppLockEnabled = false
    @AppStorage(AppStorageKey.themePreference) private var themePreference = "system"
    @AppStorage(AppStorageKey.appLanguage) private var appLanguage = "system"
    @State private var selectedTab = 0
    @State private var tabViewResetId = UUID()
    @StateObject private var authManager = AppAuthManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var router = DeepLinkRouter.shared
    
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
                            Label("Dashboard", systemImage: selectedTab == 0 ? "square.grid.2x2.fill" : "square.grid.2x2")
                        }
                        .tag(0)
                    
                    ZonesListView()
                        .tabItem {
                            Label("Domains", systemImage: selectedTab == 1 ? "globe.americas.fill" : "globe")
                        }
                        .tag(1)
                    
                    DeveloperHubView()
                        .tabItem {
                            Label("Developer", systemImage: selectedTab == 2 ? "cpu.fill" : "cpu")
                        }
                        .tag(2)
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                        }
                        .tag(3)
                }
                .id(tabViewResetId)
                .onReceive(NotificationCenter.default.publisher(for: .localCachePurged)) { _ in
                    tabViewResetId = UUID()
                }
                .onReceive(NotificationCenter.default.publisher(for: .accountSwitched)) { _ in
                    tabViewResetId = UUID()
                }
                .cloudnsSensorySelection(trigger: selectedTab)
                .overlay {
                    if isAppLockEnabled {
                        let shouldMask = !authManager.isUnlocked || scenePhase != .active
                        
                        ZStack {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .ignoresSafeArea()
                            
                            Image(systemName: "lock.shield.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary.opacity(0.6))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !authManager.isUnlocked {
                                HapticManager.impact(.light)
                                authManager.authenticate()
                            }
                        }
                        .opacity(shouldMask ? 1 : 0)
                        .allowsHitTesting(!authManager.isUnlocked && scenePhase == .active)
                        .animation(.easeInOut(duration: 0.15), value: shouldMask)
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

// MARK: - Preview

#Preview {
    ContentView()
}
