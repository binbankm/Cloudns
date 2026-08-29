import Foundation
import SwiftUI
import Combine

@MainActor
final class SpeedSettingsViewModel: BaseLoadableViewModel {
    // Speed Settings
    @Published var brotli: Bool = false
    @Published var rocketLoader: Bool = false
    @Published var earlyHints: Bool = false
    @Published var speedBrain: Bool = false
    @Published var fonts: Bool = false
    @Published var tieredCache: Bool = false
    @Published var polish: String = "off"
    
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
        } catch {
            self.brotli = previous
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateRocketLoader(zoneId: String, isOn: Bool) async {
        let previous = self.rocketLoader
        self.rocketLoader = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateRocketLoader(zoneId: zoneId, isOn: isOn)
        } catch {
            self.rocketLoader = previous
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateEarlyHints(zoneId: String, isOn: Bool) async {
        let previous = self.earlyHints
        self.earlyHints = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateEarlyHints(zoneId: zoneId, isOn: isOn)
        } catch {
            self.earlyHints = previous
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateSpeedBrain(zoneId: String, isOn: Bool) async {
        let previous = self.speedBrain
        self.speedBrain = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateSpeedBrain(zoneId: zoneId, isOn: isOn)
        } catch {
            self.speedBrain = previous
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateFonts(zoneId: String, isOn: Bool) async {
        let previous = self.fonts
        self.fonts = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateFonts(zoneId: zoneId, isOn: isOn)
        } catch {
            self.fonts = previous
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateTieredCache(zoneId: String, isOn: Bool) async {
        let previous = self.tieredCache
        self.tieredCache = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateTieredCache(zoneId: zoneId, isOn: isOn)
        } catch {
            self.tieredCache = previous
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updatePolish(zoneId: String, value: String) async {
        let previous = self.polish
        self.polish = value
        HapticManager.impact(.medium)
        do {
            try await speedService.updatePolish(zoneId: zoneId, value: value)
        } catch {
            self.polish = previous
            self.errorMessage = error.localizedDescription
        }
    }
}
