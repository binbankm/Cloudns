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
    
    @State private var deepLinkDestination: DeepLinkDestination?
    
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
            handleDeepLink(url)
        }
        .sheet(item: $deepLinkDestination) { dest in
            NavigationStack {
                switch dest {
                case .dig:
                    DNSDigToolView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { deepLinkDestination = nil }
                            }
                        }
                case .trace:
                    CFTraceToolView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { deepLinkDestination = nil }
                            }
                        }
                case .status:
                    CloudflareStatusView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { deepLinkDestination = nil }
                            }
                        }
                case .ipranges:
                    CFIpRangesToolView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { deepLinkDestination = nil }
                            }
                        }
                case .zone(let id):
                    ZoneDetailDeepLinkWrapper(zoneId: id) {
                        deepLinkDestination = nil
                    }
                }
            }
            .environment(\.locale, currentLocale)
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "cloudns" else { return }
        HapticManager.selection()
        
        let host = (url.host ?? "").lowercased()
        let path = url.path.lowercased()
        let fullUrl = url.absoluteString.lowercased()
        
        var destination: DeepLinkDestination?
        
        if host == "tools" || fullUrl.contains("tools") {
            if path.contains("dig") || fullUrl.contains("dig") {
                destination = .dig
            } else if path.contains("trace") || fullUrl.contains("trace") {
                destination = .trace
            } else if path.contains("status") || fullUrl.contains("status") {
                destination = .status
            } else if path.contains("ipranges") || fullUrl.contains("ipranges") {
                destination = .ipranges
            } else {
                selectedTab = 2
            }
        } else if host == "zone" || fullUrl.contains("cloudns://zone") {
            let zoneId = url.lastPathComponent
            if !zoneId.isEmpty && zoneId != "/" && zoneId != "zone" && zoneId != "placeholder-zone-id" && zoneId != "placeholder" {
                destination = .zone(id: zoneId)
            } else {
                selectedTab = 1
            }
        } else if host == "status" || fullUrl.contains("status") {
            destination = .status
        } else if host == "dig" || fullUrl.contains("dig") {
            destination = .dig
        } else if host == "trace" || fullUrl.contains("trace") {
            destination = .trace
        } else if host == "ipranges" || fullUrl.contains("ipranges") {
            destination = .ipranges
        }
        
        if let dest = destination {
            if deepLinkDestination != nil {
                deepLinkDestination = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.deepLinkDestination = dest
                }
            } else {
                self.deepLinkDestination = dest
            }
        }
    }
}

// MARK: - DeepLinkDestination

enum DeepLinkDestination: Identifiable {
    case zone(id: String)
    case dig
    case trace
    case status
    case ipranges
    
    var id: String {
        switch self {
        case .zone(let id): return "zone_\(id)"
        case .dig: return "dig"
        case .trace: return "trace"
        case .status: return "status"
        case .ipranges: return "ipranges"
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
