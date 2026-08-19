import Foundation
import SwiftUI
import Combine

@MainActor
class SpeedSettingsViewModel: BaseLoadableViewModel {
    // Speed Settings
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
            self.brotli = res.brotli
            self.rocketLoader = res.rocketLoader
            self.earlyHints = res.earlyHints
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
            ToastManager.shared.showSuccess("Brotli", message: isOn ? "Enabled" : "Disabled")
        } catch {
            self.brotli = previous
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func updateRocketLoader(zoneId: String, isOn: Bool) async {
        let previous = self.rocketLoader
        self.rocketLoader = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateRocketLoader(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess("Rocket Loader", message: isOn ? "Enabled" : "Disabled")
        } catch {
            self.rocketLoader = previous
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func updateEarlyHints(zoneId: String, isOn: Bool) async {
        let previous = self.earlyHints
        self.earlyHints = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateEarlyHints(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess("Early Hints", message: isOn ? "Enabled" : "Disabled")
        } catch {
            self.earlyHints = previous
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
}
