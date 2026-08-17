import Foundation
import SwiftUI
import Combine

@MainActor
class ScrapeShieldViewModel: BaseLoadableViewModel {
    @Published var emailObfuscation: String = "off"
    @Published var serverSideExcludes: String = "off"
    @Published var hotlinkProtection: String = "off"
    @Published var successMessage: String? = nil
    
    let apiClient = CloudflareAPIClient.shared
    
    // MARK: - Computed Booleans
    var emailObfuscationEnabled: Bool {
        get { emailObfuscation == "on" }
        set { emailObfuscation = newValue ? "on" : "off" }
    }
    
    var serverSideExcludesEnabled: Bool {
        get { serverSideExcludes == "on" }
        set { serverSideExcludes = newValue ? "on" : "off" }
    }
    
    var hotlinkProtectionEnabled: Bool {
        get { hotlinkProtection == "on" }
        set { hotlinkProtection = newValue ? "on" : "off" }
    }
    
    func fetchSettings(zoneId: String) async {
        await executeLoadingTask {
            let settings = try await self.apiClient.fetchZoneSettings(zoneId: zoneId)
            
            for setting in settings {
                switch setting.id {
                case "email_obfuscation":
                    self.emailObfuscation = setting.value.stringValue ?? "off"
                case "server_side_exclude":
                    self.serverSideExcludes = setting.value.stringValue ?? "off"
                case "hotlink_protection":
                    self.hotlinkProtection = setting.value.stringValue ?? "off"
                default:
                    break
                }
            }
        }
    }
    
    func updateSetting(zoneId: String, settingId: String, value: String) async {
        do {
            try await apiClient.updateZoneSetting(zoneId: zoneId, settingId: settingId, value: .string(value))
            ToastManager.shared.showSuccess("Setting Updated")
        } catch {
            self.errorMessage = "Update failed: \(error.localizedDescription)"
            ToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
}
