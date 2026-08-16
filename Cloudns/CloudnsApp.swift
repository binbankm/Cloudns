//
//  CloudnsApp.swift
//  Cloudns
//
//  Created by lbyan on 2026/8/11.
//

import SwiftUI

@main
struct CloudnsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                // Lock the app when it goes to the background
                let isAppLockEnabled = UserDefaults.standard.bool(forKey: AppStorageKey.isAppLockEnabled)
                if isAppLockEnabled {
                    AppAuthManager.shared.isUnlocked = false
                }
            }
        }
    }
}
