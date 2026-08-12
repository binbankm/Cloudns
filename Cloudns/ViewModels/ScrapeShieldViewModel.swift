import Foundation
import SwiftUI
import Combine

@MainActor
class ScrapeShieldViewModel: ObservableObject {
    @Published var emailObfuscation: String = "off"
    @Published var serverSideExcludes: String = "off"
    @Published var hotlinkProtection: String = "off"
    
    @Published var isLoading: Bool = false
    @Published var hasFetchedData: Bool = false
    @Published var errorMessage: String? = nil
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
        isLoading = true
        errorMessage = nil
        
        do {
            let settings = try await apiClient.fetchZoneSettings(zoneId: zoneId)
            
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
            
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to load settings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateSetting(zoneId: String, settingId: String, value: String) async {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        
        do {
            try await apiClient.updateZoneSetting(zoneId: zoneId, settingId: settingId, value: .string(value))
            
            successMessage = "Setting updated."
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.successMessage = nil
            }
        } catch {
            self.errorMessage = "Update failed: \(error.localizedDescription)"
            
            let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.error)
        }
    }
}
