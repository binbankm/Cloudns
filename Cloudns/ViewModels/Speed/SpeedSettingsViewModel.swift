import Combine
import Foundation
import SwiftUI

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

    private let speedService: SpeedSettingsServiceProtocol

    init(speedService: SpeedSettingsServiceProtocol = SpeedSettingsService.shared) {
        self.speedService = speedService
        super.init()
    }

    func fetchSettings(zoneId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let res = try await speedService.getSpeedSettings(zoneId: zoneId)
            brotli = res.brotli
            rocketLoader = res.rocketLoader
            earlyHints = res.earlyHints
            speedBrain = res.speedBrain
            fonts = res.fonts
            tieredCache = res.tieredCache
            polish = res.polish
            hasFetchedData = true
        } catch {
            errorMessage = "Failed to load speed settings: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func updateBrotli(zoneId: String, isOn: Bool) async {
        let previous = brotli
        brotli = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateBrotli(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess(isOn ? LocalizedStringKey("Brotli Enabled") : LocalizedStringKey("Brotli Disabled"))
        } catch {
            brotli = previous
            errorMessage = error.localizedDescription
        }
    }

    func updateRocketLoader(zoneId: String, isOn: Bool) async {
        let previous = rocketLoader
        rocketLoader = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateRocketLoader(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess(isOn ? LocalizedStringKey("Rocket Loader Enabled") : LocalizedStringKey("Rocket Loader Disabled"))
        } catch {
            rocketLoader = previous
            errorMessage = error.localizedDescription
        }
    }

    func updateEarlyHints(zoneId: String, isOn: Bool) async {
        let previous = earlyHints
        earlyHints = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateEarlyHints(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess(isOn ? LocalizedStringKey("Early Hints Enabled") : LocalizedStringKey("Early Hints Disabled"))
        } catch {
            earlyHints = previous
            errorMessage = error.localizedDescription
        }
    }

    func updateSpeedBrain(zoneId: String, isOn: Bool) async {
        let previous = speedBrain
        speedBrain = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateSpeedBrain(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess(isOn ? LocalizedStringKey("Speed Brain Enabled") : LocalizedStringKey("Speed Brain Disabled"))
        } catch {
            speedBrain = previous
            errorMessage = error.localizedDescription
        }
    }

    func updateFonts(zoneId: String, isOn: Bool) async {
        let previous = fonts
        fonts = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateFonts(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess(isOn ? LocalizedStringKey("Fonts Enabled") : LocalizedStringKey("Fonts Disabled"))
        } catch {
            fonts = previous
            errorMessage = error.localizedDescription
        }
    }

    func updateTieredCache(zoneId: String, isOn: Bool) async {
        let previous = tieredCache
        tieredCache = isOn
        HapticManager.impact(.medium)
        do {
            try await speedService.updateTieredCache(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess(isOn ? LocalizedStringKey("Tiered Cache Enabled") : LocalizedStringKey("Tiered Cache Disabled"))
        } catch {
            tieredCache = previous
            errorMessage = error.localizedDescription
        }
    }

    func updatePolish(zoneId: String, value: String) async {
        let previous = polish
        polish = value
        HapticManager.impact(.medium)
        do {
            try await speedService.updatePolish(zoneId: zoneId, value: value)
        } catch {
            polish = previous
            errorMessage = error.localizedDescription
        }
    }
}
