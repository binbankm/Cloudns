//
//  ContentView.swift
//  Cloudns
//
//  Created by lbyan on 2026/8/11.
//

import SwiftUI

struct ContentView: View {
    @AppStorage(AppStorageKey.isLoggedIn) private var isLoggedIn = false
    @AppStorage(AppStorageKey.hasSeenOnboarding) private var hasSeenOnboarding = false
    @AppStorage(AppStorageKey.isAppLockEnabled) private var isAppLockEnabled = false
    @AppStorage(AppStorageKey.themePreference) private var themePreference = "system"
    @AppStorage(AppStorageKey.appLanguage) private var appLanguage = "system"
    @State private var selectedTab = 0
    @StateObject private var authManager = AppAuthManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var currentLocale: Locale {
        if appLanguage == "system" {
            return Locale.autoupdatingCurrent
        }
        return Locale(identifier: appLanguage)
    }
    
    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if isLoggedIn {
                ZStack {
                    TabView(selection: $selectedTab) {
                        DashboardView()
                            .tabItem {
                                Label("Dashboard", systemImage: "square.grid.2x2")
                            }
                            .tag(0)
                        
                        ZonesListView()
                            .tabItem {
                                Label("Domains", systemImage: "network")
                            }
                            .tag(1)
                        
                        DeveloperHubView()
                            .tabItem {
                                Label("Developer", systemImage: "cpu")
                            }
                            .tag(2)
                        
                        SettingsView()
                            .tabItem {
                                Label("Settings", systemImage: "gearshape")
                            }
                            .tag(3)
                    }
                    .blur(radius: (isAppLockEnabled && scenePhase != .active) ? 15 : 0)
                    
                    if isAppLockEnabled && !authManager.isUnlocked {
                        AppLockView()
                    }
                }
            } else {
                LoginView()
            }
        }
        .animation(.default, value: isLoggedIn)
        .animation(.default, value: hasSeenOnboarding)
        .animation(.default, value: authManager.isUnlocked)
        .toastContainer()
        .preferredColorScheme(themePreference == "light" ? .light : (themePreference == "dark" ? .dark : nil))
        .environment(\.locale, currentLocale)
        .id(appLanguage)
        .onAppear {
            _ = AccountManager.shared
        }
    }
}

#Preview {
    ContentView()
}
