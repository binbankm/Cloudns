//
//  ContentView.swift
//  Cloudns
//
//  Created by lbyan on 2026/8/11.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    @AppStorage("themePreference") private var themePreference = "system"
    
    @StateObject private var authManager = AppAuthManager.shared
    
    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if isLoggedIn {
                ZStack {
                    TabView {
                        ZonesListView()
                            .tabItem {
                                Label("Domains", systemImage: "network")
                            }
                        
                        SettingsView()
                            .tabItem {
                                Label("Settings", systemImage: "gearshape")
                            }
                    }
                    
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
        .preferredColorScheme(themePreference == "light" ? .light : (themePreference == "dark" ? .dark : nil))
        .onAppear {
            _ = AccountManager.shared
        }
    }
}

#Preview {
    ContentView()
}
