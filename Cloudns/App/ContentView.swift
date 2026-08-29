import SwiftUI

// MARK: - ContentView

struct ContentView: View {
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
                    
                    NetworkToolsView()
                        .tabItem {
                            Label("Tools", systemImage: selectedTab == .tools ? "terminal.fill" : "terminal")
                        }
                        .tag(AppTab.tools)
                    
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
                .onChange(of: selectedTab) { _ in HapticManager.selection() }
                .overlay(alignment: .top) {
                    if !networkMonitor.isConnected {
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
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: networkMonitor.isConnected)
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
        .overlay(alignment: .top) {
            HIGToastOverlay()
        }
        .environment(\.locale, currentLocale)
        .preferredColorScheme(themePreference == "light" ? ColorScheme.light : (themePreference == "dark" ? ColorScheme.dark : nil))
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
