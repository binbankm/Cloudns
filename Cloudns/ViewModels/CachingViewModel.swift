import Foundation
import SwiftUI
import Combine

@MainActor
class CachingViewModel: ObservableObject {
    @Published var cacheLevel: String = "basic"
    @Published var browserCacheTTL: Int = 14400
    @Published var alwaysOnline: Bool = false
    @Published var developmentMode: Bool = false
    
    @Published var isLoading: Bool = false
    @Published var hasFetchedData: Bool = false
    @Published var errorMessage: String? = nil
    
    // For Purge Cache UI
    @Published var isPurging: Bool = false
    @Published var purgeSuccessMessage: String? = nil
    @Published var purgeErrorMessage: String? = nil
    
    let apiClient = CloudflareAPIClient.shared
    
    func fetchSettings(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let settings = try await apiClient.fetchZoneSettings(zoneId: zoneId)
            
            for setting in settings {
                if setting.id == "cache_level", let val = setting.value.stringValue {
                    self.cacheLevel = val
                } else if setting.id == "browser_cache_ttl", let val = setting.value.intValue {
                    self.browserCacheTTL = val
                } else if setting.id == "always_online", let val = setting.value.stringValue {
                    self.alwaysOnline = (val == "on")
                } else if setting.id == "development_mode", let val = setting.value.stringValue {
                    self.developmentMode = (val == "on")
                }
            }
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to fetch caching settings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func purgeCacheEverything(zoneId: String) async {
        isPurging = true
        purgeSuccessMessage = nil
        purgeErrorMessage = nil
        
        do {
            try await apiClient.purgeCacheEverything(zoneId: zoneId)
            purgeSuccessMessage = "Successfully purged all cache!"
            ToastManager.shared.showSuccess("Cache Purged", message: "All cached resources were purged successfully.")
        } catch {
            purgeErrorMessage = "Failed to purge cache: \(error.localizedDescription)"
            ToastManager.shared.showError("Purge Cache Failed", message: error.localizedDescription)
        }
        
        isPurging = false
    }
    
    func purgeCacheByURLs(zoneId: String, urls: [String]) async {
        isPurging = true
        purgeSuccessMessage = nil
        purgeErrorMessage = nil
        
        do {
            try await apiClient.purgeCacheByURLs(zoneId: zoneId, urls: urls)
            purgeSuccessMessage = "Successfully purged requested URLs!"
            ToastManager.shared.showSuccess("URLs Purged", message: "\(urls.count) URL(s) purged from cache.")
        } catch {
            purgeErrorMessage = "Failed to purge URLs: \(error.localizedDescription)"
            ToastManager.shared.showError("Purge URLs Failed", message: error.localizedDescription)
        }
        
        isPurging = false
    }

    func purgeCacheByHosts(zoneId: String, hosts: [String]) async {
        isPurging = true
        purgeSuccessMessage = nil
        purgeErrorMessage = nil
        
        do {
            try await apiClient.purgeCacheByHosts(zoneId: zoneId, hosts: hosts)
            purgeSuccessMessage = "Successfully purged requested Hosts!"
            ToastManager.shared.showSuccess("Hosts Purged", message: "\(hosts.count) host(s) purged from cache.")
        } catch {
            purgeErrorMessage = "Failed to purge hosts: \(error.localizedDescription)"
            ToastManager.shared.showError("Purge Hosts Failed", message: error.localizedDescription)
        }
        
        isPurging = false
    }

    func purgeCacheByPrefixes(zoneId: String, prefixes: [String]) async {
        isPurging = true
        purgeSuccessMessage = nil
        purgeErrorMessage = nil
        
        do {
            try await apiClient.purgeCacheByPrefixes(zoneId: zoneId, prefixes: prefixes)
            purgeSuccessMessage = "Successfully purged requested URL prefixes!"
            ToastManager.shared.showSuccess("Prefixes Purged", message: "\(prefixes.count) prefix(es) purged from cache.")
        } catch {
            purgeErrorMessage = "Failed to purge prefixes: \(error.localizedDescription)"
            ToastManager.shared.showError("Purge Prefixes Failed", message: error.localizedDescription)
        }
        
        isPurging = false
    }

    func purgeCacheByTags(zoneId: String, tags: [String]) async {
        isPurging = true
        purgeSuccessMessage = nil
        purgeErrorMessage = nil
        
        do {
            try await apiClient.purgeCacheByTags(zoneId: zoneId, tags: tags)
            purgeSuccessMessage = "Successfully purged requested Cache-Tags!"
            ToastManager.shared.showSuccess("Tags Purged", message: "\(tags.count) tag(s) purged from cache.")
        } catch {
            purgeErrorMessage = "Failed to purge tags: \(error.localizedDescription)"
            ToastManager.shared.showError("Purge Tags Failed", message: error.localizedDescription)
        }
        
        isPurging = false
    }
    
    func updateCacheLevel(zoneId: String, level: String) async {
        await updateSetting(zoneId: zoneId, settingId: "cache_level", value: .string(level)) {
            self.cacheLevel = level
        }
    }
    
    func updateBrowserCacheTTL(zoneId: String, ttl: Int) async {
        await updateSetting(zoneId: zoneId, settingId: "browser_cache_ttl", value: .int(ttl)) {
            self.browserCacheTTL = ttl
        }
    }
    
    func updateAlwaysOnline(zoneId: String, isOn: Bool) async {
        await updateSetting(zoneId: zoneId, settingId: "always_online", value: .string(isOn ? "on" : "off")) {
            self.alwaysOnline = isOn
        }
    }
    
    func updateDevelopmentMode(zoneId: String, isOn: Bool) async {
        await updateSetting(zoneId: zoneId, settingId: "development_mode", value: .string(isOn ? "on" : "off")) {
            self.developmentMode = isOn
            NotificationCenter.default.post(name: .zoneUpdated, object: nil)
        }
    }
    
    private func updateSetting(zoneId: String, settingId: String, value: SettingValue, onSuccess: @escaping () -> Void) async {
        do {
            try await apiClient.updateZoneSetting(zoneId: zoneId, settingId: settingId, value: value)
            onSuccess()
        } catch {
            self.errorMessage = "Failed to update \(settingId): \(error.localizedDescription)"
        }
    }
}
