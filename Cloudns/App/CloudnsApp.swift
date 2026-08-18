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
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
