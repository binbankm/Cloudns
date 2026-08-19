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
    @State private var tabViewResetId = UUID()
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
                                .font(.system(size: 48, weight: .light))
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
        .toastContainer()
        .preferredColorScheme(themePreference == "light" ? .light : (themePreference == "dark" ? .dark : nil))
        .environment(\.locale, currentLocale)
        .id(appLanguage)
        .onAppear {
            _ = AccountManager.shared
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
    }
}

#Preview {
    ContentView()
}
