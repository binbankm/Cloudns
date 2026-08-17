import Foundation
import SwiftUI
import Combine

@MainActor
class SecurityViewModel: BaseLoadableViewModel {
    @Published var securityLevel: String = "medium"
    @Published var challengeTTL: Int = 1800
    @Published var browserCheck: Bool = true
    @Published var botFightMode: Bool = false
    
    let apiClient = CloudflareAPIClient.shared
    
    func fetchSettings(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let settings = try await apiClient.fetchZoneSettings(zoneId: zoneId)
            
            for setting in settings {
                if setting.id == "security_level", let val = setting.value.stringValue {
                    self.securityLevel = val
                } else if setting.id == "challenge_ttl", let val = setting.value.intValue {
                    self.challengeTTL = val
                } else if setting.id == "browser_check", let val = setting.value.stringValue {
                    self.browserCheck = (val == "on")
                } else if setting.id == "bot_fight_mode", let val = setting.value.stringValue {
                    self.botFightMode = (val == "on")
                }
            }
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to fetch security settings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateSecurityLevel(zoneId: String, level: String) async {
        await updateSetting(zoneId: zoneId, settingId: "security_level", value: .string(level)) {
            self.securityLevel = level
        }
    }
    
    func updateChallengeTTL(zoneId: String, ttl: Int) async {
        await updateSetting(zoneId: zoneId, settingId: "challenge_ttl", value: .int(ttl)) {
            self.challengeTTL = ttl
        }
    }
    
    func updateBrowserCheck(zoneId: String, isOn: Bool) async {
        await updateSetting(zoneId: zoneId, settingId: "browser_check", value: .string(isOn ? "on" : "off")) {
            self.browserCheck = isOn
        }
    }
    
    func updateBotFightMode(zoneId: String, isOn: Bool) async {
        await updateSetting(zoneId: zoneId, settingId: "bot_fight_mode", value: .string(isOn ? "on" : "off")) {
            self.botFightMode = isOn
        }
    }
    
    private func updateSetting(zoneId: String, settingId: String, value: SettingValue, onSuccess: @escaping () -> Void) async {
        // Haptic feedback for setting update trigger
        HapticManager.impact(.medium)
        
        do {
            try await apiClient.updateZoneSetting(zoneId: zoneId, settingId: settingId, value: value)
            onSuccess()
        } catch {
            self.errorMessage = "Failed to update \(settingId): \(error.localizedDescription)"
        }
    }
}
