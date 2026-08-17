import Foundation
import SwiftUI
import Combine

@MainActor
class NetworkSettingsViewModel: BaseLoadableViewModel {
    @Published var ipv6: Bool = false
    @Published var websockets: Bool = false
    @Published var http2: Bool = false
    @Published var http3: Bool = false
    @Published var ipGeolocation: Bool = false
    
    let apiClient = CloudflareAPIClient.shared
    
    func fetchSettings(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let settings = try await apiClient.fetchZoneSettings(zoneId: zoneId)
            
            for setting in settings {
                switch setting.id {
                case "ipv6":
                    self.ipv6 = (setting.value.stringValue == "on")
                case "websockets":
                    self.websockets = (setting.value.stringValue == "on")
                case "http2":
                    self.http2 = (setting.value.stringValue == "on")
                case "http3":
                    self.http3 = (setting.value.stringValue == "on")
                case "ip_geolocation":
                    self.ipGeolocation = (setting.value.stringValue == "on")
                default:
                    break
                }
            }
            
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to load network settings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateIPv6(zoneId: String, isOn: Bool) async {
        await updateSetting(zoneId: zoneId, settingId: "ipv6", value: isOn) {
            self.ipv6 = isOn
        }
    }
    
    func updateWebsockets(zoneId: String, isOn: Bool) async {
        await updateSetting(zoneId: zoneId, settingId: "websockets", value: isOn) {
            self.websockets = isOn
        }
    }
    
    func updateHTTP2(zoneId: String, isOn: Bool) async {
        await updateSetting(zoneId: zoneId, settingId: "http2", value: isOn) {
            self.http2 = isOn
        }
    }
    
    func updateHTTP3(zoneId: String, isOn: Bool) async {
        await updateSetting(zoneId: zoneId, settingId: "http3", value: isOn) {
            self.http3 = isOn
        }
    }
    
    func updateIPGeolocation(zoneId: String, isOn: Bool) async {
        await updateSetting(zoneId: zoneId, settingId: "ip_geolocation", value: isOn) {
            self.ipGeolocation = isOn
        }
    }
    
    private func updateSetting(zoneId: String, settingId: String, value: Bool, onSuccess: (() -> Void)? = nil) async {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        do {
            try await apiClient.updateZoneSetting(zoneId: zoneId, settingId: settingId, value: .string(value ? "on" : "off"))
            onSuccess?()
        } catch {
            self.errorMessage = "Failed to update \(settingId.replacingOccurrences(of: "_", with: " ")): \(error.localizedDescription)"
        }
    }
}
