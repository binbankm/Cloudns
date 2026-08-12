import Foundation
import SwiftUI
import Combine

@MainActor
class SSLSettingsViewModel: ObservableObject {
    @Published var sslMode: String = "off"
    @Published var alwaysUseHTTPS: Bool = false
    @Published var automaticHTTPSRewrites: Bool = false
    @Published var minTLSVersion: String = "1.0"
    @Published var tls13: Bool = false
    @Published var opportunisticEncryption: Bool = false
    @Published var opportunisticOnion: Bool = false
    
    // HSTS
    @Published var hstsEnabled: Bool = false
    @Published var hstsMaxAge: Int = 0
    @Published var hstsIncludeSubdomains: Bool = false
    @Published var hstsNoSniff: Bool = false
    
    @Published var isLoading: Bool = false
    @Published var hasFetchedData: Bool = false
    @Published var errorMessage: String? = nil
    
    let apiClient = CloudflareAPIClient.shared
    
    func fetchSettings(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let settings = try await apiClient.fetchZoneSettings(zoneId: zoneId)
            
            for setting in settings {
                if setting.id == "ssl", let val = setting.value.stringValue {
                    self.sslMode = val
                } else if setting.id == "always_use_https", let val = setting.value.stringValue {
                    self.alwaysUseHTTPS = (val == "on")
                } else if setting.id == "automatic_https_rewrites", let val = setting.value.stringValue {
                    self.automaticHTTPSRewrites = (val == "on")
                } else if setting.id == "min_tls_version", let val = setting.value.stringValue {
                    self.minTLSVersion = val
                } else if setting.id == "tls_1_3", let val = setting.value.stringValue {
                    self.tls13 = (val == "on")
                } else if setting.id == "opportunistic_encryption", let val = setting.value.stringValue {
                    self.opportunisticEncryption = (val == "on")
                } else if setting.id == "opportunistic_onion", let val = setting.value.stringValue {
                    self.opportunisticOnion = (val == "on")
                } else if setting.id == "security_header", case let .securityHeader(header) = setting.value {
                    let hsts = header.strict_transport_security
                    self.hstsEnabled = hsts.enabled
                    self.hstsMaxAge = hsts.max_age
                    self.hstsIncludeSubdomains = hsts.include_subdomains
                    self.hstsNoSniff = hsts.nosniff
                }
            }
            self.hasFetchedData = true
        } catch APIError.decodingError(let error) {
            self.errorMessage = "Decoding failed. Error: \(error.localizedDescription)"
        } catch APIError.cloudflareError(let message) {
            self.errorMessage = message
        } catch {
            self.errorMessage = "Failed to fetch SSL settings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateSSLMode(zoneId: String, mode: String) async {
        await updateSetting(zoneId: zoneId, settingId: "ssl", value: .string(mode)) {
            self.sslMode = mode
        }
    }
    
    func updateAlwaysUseHTTPS(zoneId: String, isOn: Bool) async {
        await updateSetting(zoneId: zoneId, settingId: "always_use_https", value: .string(isOn ? "on" : "off")) {
            self.alwaysUseHTTPS = isOn
        }
    }
    
    func updateAutomaticHTTPSRewrites(zoneId: String, isOn: Bool) async {
        await updateSetting(zoneId: zoneId, settingId: "automatic_https_rewrites", value: .string(isOn ? "on" : "off")) {
            self.automaticHTTPSRewrites = isOn
        }
    }
    
    func updateMinTLSVersion(zoneId: String, version: String) async {
        await updateSetting(zoneId: zoneId, settingId: "min_tls_version", value: .string(version)) {
            self.minTLSVersion = version
        }
    }
    
    func updateTLS13(zoneId: String, isOn: Bool) async {
        await updateSetting(zoneId: zoneId, settingId: "tls_1_3", value: .string(isOn ? "on" : "off")) {
            self.tls13 = isOn
        }
    }
    
    func updateOpportunisticEncryption(zoneId: String, isOn: Bool) async {
        await updateSetting(zoneId: zoneId, settingId: "opportunistic_encryption", value: .string(isOn ? "on" : "off")) {
            self.opportunisticEncryption = isOn
        }
    }
    
    func updateOpportunisticOnion(zoneId: String, isOn: Bool) async {
        await updateSetting(zoneId: zoneId, settingId: "opportunistic_onion", value: .string(isOn ? "on" : "off")) {
            self.opportunisticOnion = isOn
        }
    }
    
    func updateHSTS(zoneId: String, enabled: Bool, maxAge: Int, subdomains: Bool, nosniff: Bool) async {
        let hsts = SecurityHeader.StrictTransportSecurity(
            enabled: enabled,
            max_age: maxAge,
            include_subdomains: subdomains,
            nosniff: nosniff
        )
        let header = SecurityHeader(strict_transport_security: hsts)
        
        await updateSetting(zoneId: zoneId, settingId: "security_header", value: .securityHeader(header)) {
            self.hstsEnabled = enabled
            self.hstsMaxAge = maxAge
            self.hstsIncludeSubdomains = subdomains
            self.hstsNoSniff = nosniff
        }
    }
    
    private func updateSetting(zoneId: String, settingId: String, value: SettingValue, onSuccess: @escaping () -> Void) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiClient.updateZoneSetting(zoneId: zoneId, settingId: settingId, value: value)
            onSuccess()
        } catch APIError.cloudflareError(let message) {
            self.errorMessage = message
        } catch {
            self.errorMessage = "Failed to update \(settingId)."
        }
        
        isLoading = false
    }
}
