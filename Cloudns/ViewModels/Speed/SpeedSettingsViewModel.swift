import Foundation
import SwiftUI
import Combine

@MainActor
class SpeedSettingsViewModel: BaseLoadableViewModel {
    // Minify Settings
    @Published var minifyCSS: Bool = false
    @Published var minifyHTML: Bool = false
    @Published var minifyJS: Bool = false
    
    // Other Speed Settings
    @Published var brotli: Bool = false
    @Published var rocketLoader: Bool = false
    @Published var earlyHints: Bool = false
    
    private let speedService: SpeedAndNetworkServiceProtocol
    
    init(speedService: SpeedAndNetworkServiceProtocol = SpeedAndNetworkService.shared) {
        self.speedService = speedService
        super.init()
    }
    
    func fetchSettings(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let res = try await speedService.getSpeedSettings(zoneId: zoneId)
            self.minifyCSS = res.minifyCSS
            self.minifyHTML = res.minifyHTML
            self.minifyJS = res.minifyJS
            self.brotli = res.brotli
            self.rocketLoader = res.rocketLoader
            self.earlyHints = res.earlyHints
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to load speed settings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateMinify(zoneId: String, css: Bool, html: Bool, js: Bool) async {
        HapticManager.impact(.medium)
        do {
            try await speedService.updateMinify(zoneId: zoneId, css: css, html: html, js: js)
            self.minifyCSS = css
            self.minifyHTML = html
            self.minifyJS = js
        } catch {
            self.errorMessage = "Failed to update minify settings: \(error.localizedDescription)"
        }
    }
    
    func updateBrotli(zoneId: String, isOn: Bool) async {
        HapticManager.impact(.medium)
        do {
            try await speedService.updateBrotli(zoneId: zoneId, isOn: isOn)
            self.brotli = isOn
        } catch {
            self.errorMessage = "Failed to update Brotli: \(error.localizedDescription)"
        }
    }
    
    func updateRocketLoader(zoneId: String, isOn: Bool) async {
        HapticManager.impact(.medium)
        do {
            try await speedService.updateRocketLoader(zoneId: zoneId, isOn: isOn)
            self.rocketLoader = isOn
        } catch {
            self.errorMessage = "Failed to update Rocket Loader: \(error.localizedDescription)"
        }
    }
    
    func updateEarlyHints(zoneId: String, isOn: Bool) async {
        HapticManager.impact(.medium)
        do {
            try await speedService.updateEarlyHints(zoneId: zoneId, isOn: isOn)
            self.earlyHints = isOn
        } catch {
            self.errorMessage = "Failed to update Early Hints: \(error.localizedDescription)"
        }
    }
}
