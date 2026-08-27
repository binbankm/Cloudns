import Foundation
import SwiftUI
import Combine

@MainActor
final class SpeedSettingsViewModel: BaseLoadableViewModel {
    // Speed Settings
    // MARK: - Published Properties
    @Published var brotli: Bool = false
    @Published var rocketLoader: Bool = false
    @Published var earlyHints: Bool = false
    @Published var speedBrain: Bool = false
    @Published var fonts: Bool = false
    @Published var tieredCache: Bool = false
    @Published var polish: String = "off"
    
    // MARK: - Private Properties
    private let speedService: SpeedAndNetworkServiceProtocol
    
    // MARK: - Lifecycle / Init
    init(speedService: SpeedAndNetworkServiceProtocol = SpeedAndNetworkService.shared) {
        self.speedService = speedService
        super.init()
    }
    
    // MARK: - Public Methods
    func fetchSettings(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let res = try await speedService.getSpeedSettings(zoneId: zoneId)
            self.brotli = res.brotli
            self.rocketLoader = res.rocketLoader
            self.earlyHints = res.earlyHints
            self.speedBrain = res.speedBrain
            self.fonts = res.fonts
            self.tieredCache = res.tieredCache
            self.polish = res.polish
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to load speed settings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateBrotli(zoneId: String, isOn: Bool) async {
        let previous = self.brotli
        self.brotli = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateBrotli(zoneId: zoneId, isOn: isOn)
            CloudnsToastManager.shared.showSuccess("Brotli", message: isOn ? "Enabled" : "Disabled")
        } catch {
            self.brotli = previous
            self.errorMessage = error.localizedDescription
            CloudnsToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func updateRocketLoader(zoneId: String, isOn: Bool) async {
        let previous = self.rocketLoader
        self.rocketLoader = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateRocketLoader(zoneId: zoneId, isOn: isOn)
            CloudnsToastManager.shared.showSuccess("Rocket Loader", message: isOn ? "Enabled" : "Disabled")
        } catch {
            self.rocketLoader = previous
            self.errorMessage = error.localizedDescription
            CloudnsToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func updateEarlyHints(zoneId: String, isOn: Bool) async {
        let previous = self.earlyHints
        self.earlyHints = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateEarlyHints(zoneId: zoneId, isOn: isOn)
            CloudnsToastManager.shared.showSuccess("Early Hints", message: isOn ? "Enabled" : "Disabled")
        } catch {
            self.earlyHints = previous
            self.errorMessage = error.localizedDescription
            CloudnsToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func updateSpeedBrain(zoneId: String, isOn: Bool) async {
        let previous = self.speedBrain
        self.speedBrain = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateSpeedBrain(zoneId: zoneId, isOn: isOn)
            CloudnsToastManager.shared.showSuccess("Speed Brain", message: isOn ? "Enabled" : "Disabled")
        } catch {
            self.speedBrain = previous
            self.errorMessage = error.localizedDescription
            CloudnsToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func updateFonts(zoneId: String, isOn: Bool) async {
        let previous = self.fonts
        self.fonts = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateFonts(zoneId: zoneId, isOn: isOn)
            CloudnsToastManager.shared.showSuccess("Cloudflare Fonts", message: isOn ? "Enabled" : "Disabled")
        } catch {
            self.fonts = previous
            self.errorMessage = error.localizedDescription
            CloudnsToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func updateTieredCache(zoneId: String, isOn: Bool) async {
        let previous = self.tieredCache
        self.tieredCache = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateTieredCache(zoneId: zoneId, isOn: isOn)
            CloudnsToastManager.shared.showSuccess("Tiered Cache", message: isOn ? "Enabled" : "Disabled")
        } catch {
            self.tieredCache = previous
            self.errorMessage = error.localizedDescription
            CloudnsToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func updatePolish(zoneId: String, value: String) async {
        let previous = self.polish
        self.polish = value
        HapticManager.impact(.medium)
        do {
            try await speedService.updatePolish(zoneId: zoneId, value: value)
            CloudnsToastManager.shared.showSuccess("Polish", message: "Updated to \(value.capitalized)")
        } catch {
            self.polish = previous
            self.errorMessage = error.localizedDescription
            CloudnsToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
}
