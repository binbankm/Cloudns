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
    
    let apiClient = CloudflareAPIClient.shared
    
    func fetchSettings(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let settings = try await apiClient.fetchZoneSettings(zoneId: zoneId)
            
            for setting in settings {
                switch setting.id {
                case "minify":
                    if case .object(let dict) = setting.value {
                        self.minifyCSS = (dict["css"] == "on")
                        self.minifyHTML = (dict["html"] == "on")
                        self.minifyJS = (dict["js"] == "on")
                    }
                case "brotli":
                    self.brotli = (setting.value.stringValue == "on")
                case "rocket_loader":
                    self.rocketLoader = (setting.value.stringValue == "on")
                case "early_hints":
                    self.earlyHints = (setting.value.stringValue == "on")
                default:
                    break
                }
            }
            
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to load speed settings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateMinify(zoneId: String, css: Bool, html: Bool, js: Bool) async {
        let dict = [
            "css": css ? "on" : "off",
            "html": html ? "on" : "off",
            "js": js ? "on" : "off"
        ]
        
        await updateSetting(zoneId: zoneId, settingId: "minify", value: .object(dict))
    }
    
    func updateBrotli(zoneId: String, isOn: Bool) async {
        await updateSetting(zoneId: zoneId, settingId: "brotli", value: .string(isOn ? "on" : "off")) {
            self.brotli = isOn
        }
    }
    
    func updateRocketLoader(zoneId: String, isOn: Bool) async {
        await updateSetting(zoneId: zoneId, settingId: "rocket_loader", value: .string(isOn ? "on" : "off")) {
            self.rocketLoader = isOn
        }
    }
    
    func updateEarlyHints(zoneId: String, isOn: Bool) async {
        await updateSetting(zoneId: zoneId, settingId: "early_hints", value: .string(isOn ? "on" : "off")) {
            self.earlyHints = isOn
        }
    }
    
    private func updateSetting(zoneId: String, settingId: String, value: SettingValue, onSuccess: (() -> Void)? = nil) async {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        do {
            try await apiClient.updateZoneSetting(zoneId: zoneId, settingId: settingId, value: value)
            onSuccess?()
        } catch {
            self.errorMessage = "Failed to update \(settingId.replacingOccurrences(of: "_", with: " ")): \(error.localizedDescription)"
        }
    }
}
