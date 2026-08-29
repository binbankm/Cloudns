import Foundation
import SwiftUI
import Combine

@MainActor
final class CachingViewModel: BaseLoadableViewModel {
    @Published var cacheLevel: String = "basic"
    @Published var browserCacheTTL: Int = 14400
    @Published var alwaysOnline: Bool = false
    @Published var developmentMode: Bool = false
    
    // For Purge Cache UI
    @Published var isPurging: Bool = false
    @Published var purgeSuccessMessage: String?
    @Published var purgeErrorMessage: String?
    
    private let cachingService: SpeedAndNetworkServiceProtocol
    
    init(cachingService: SpeedAndNetworkServiceProtocol = SpeedAndNetworkService.shared) {
        self.cachingService = cachingService
        super.init()
    }
    
    func fetchSettings(zoneId: String) async {
        await executeLoadingTask {
            let res = try await self.cachingService.getCachingSettings(zoneId: zoneId)
            self.cacheLevel = res.cacheLevel
            self.browserCacheTTL = res.browserTTL
            self.alwaysOnline = res.alwaysOnline
            self.developmentMode = res.devMode
            self.hasFetchedData = true
        }
    }
    
    func purgeCacheEverything(zoneId: String) async {
        isPurging = true
        purgeSuccessMessage = nil
        purgeErrorMessage = nil
        
        do {
            try await cachingService.purgeEverything(zoneId: zoneId)
            purgeSuccessMessage = "Successfully purged all cache!"
            ToastManager.shared.showSuccess("Entire Cache Purged", icon: "trash.circle.fill")
        } catch {
            purgeErrorMessage = "Failed to purge cache: \(error.localizedDescription)"
            ToastManager.shared.showError("Failed to purge cache")
        }
        
        isPurging = false
    }
    
    func purgeCacheByURLs(zoneId: String, urls: [String]) async {
        isPurging = true
        purgeSuccessMessage = nil
        purgeErrorMessage = nil
        
        do {
            try await cachingService.purgeCacheByURLs(zoneId: zoneId, urls: urls)
            purgeSuccessMessage = "Successfully purged requested URLs!"
            ToastManager.shared.showSuccess("Custom Cache Purged", icon: "checkmark.circle.fill")
        } catch {
            purgeErrorMessage = "Failed to purge URLs: \(error.localizedDescription)"
            ToastManager.shared.showError("Failed to purge URLs")
        }
        
        isPurging = false
    }

    func purgeCacheByHosts(zoneId: String, hosts: [String]) async {
        isPurging = true
        purgeSuccessMessage = nil
        purgeErrorMessage = nil
        
        do {
            try await cachingService.purgeCacheByHosts(zoneId: zoneId, hosts: hosts)
            purgeSuccessMessage = "Successfully purged requested Hosts!"
        } catch {
            purgeErrorMessage = "Failed to purge hosts: \(error.localizedDescription)"
        }
        
        isPurging = false
    }

    func purgeCacheByPrefixes(zoneId: String, prefixes: [String]) async {
        isPurging = true
        purgeSuccessMessage = nil
        purgeErrorMessage = nil
        
        do {
            try await cachingService.purgeCacheByPrefixes(zoneId: zoneId, prefixes: prefixes)
            purgeSuccessMessage = "Successfully purged requested URL prefixes!"
        } catch {
            purgeErrorMessage = "Failed to purge prefixes: \(error.localizedDescription)"
        }
        
        isPurging = false
    }

    func purgeCacheByTags(zoneId: String, tags: [String]) async {
        isPurging = true
        purgeSuccessMessage = nil
        purgeErrorMessage = nil
        
        do {
            try await cachingService.purgeCacheByTags(zoneId: zoneId, tags: tags)
            purgeSuccessMessage = "Successfully purged requested Cache-Tags!"
        } catch {
            purgeErrorMessage = "Failed to purge tags: \(error.localizedDescription)"
        }
        
        isPurging = false
    }
    
    func updateCacheLevel(zoneId: String, level: String) async {
        let prev = self.cacheLevel
        self.cacheLevel = level
        do {
            try await cachingService.updateCacheLevel(zoneId: zoneId, level: level)
        } catch {
            self.cacheLevel = prev
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateBrowserCacheTTL(zoneId: String, ttl: Int) async {
        let prev = self.browserCacheTTL
        self.browserCacheTTL = ttl
        do {
            try await cachingService.updateBrowserCacheTTL(zoneId: zoneId, ttl: ttl)
        } catch {
            self.browserCacheTTL = prev
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateAlwaysOnline(zoneId: String, isOn: Bool) async {
        let prev = self.alwaysOnline
        self.alwaysOnline = isOn
        do {
            try await cachingService.updateAlwaysOnline(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess(isOn ? "Always Online Enabled" : "Always Online Disabled", icon: "bolt.horizontal.fill")
        } catch {
            self.alwaysOnline = prev
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Failed to update Always Online")
        }
    }
    
    func updateDevelopmentMode(zoneId: String, isOn: Bool) async {
        let prev = self.developmentMode
        self.developmentMode = isOn
        do {
            try await cachingService.updateDevelopmentMode(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess(isOn ? "Development Mode Enabled" : "Development Mode Disabled")
            await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("zone_details_\(zoneId)"))
            NotificationCenter.default.post(name: .zoneUpdated, object: nil, userInfo: ["zoneId": zoneId])
            ToastManager.shared.showSuccess(isOn ? "Development Mode Enabled" : "Development Mode Disabled", icon: "hammer.fill")
        } catch {
            self.developmentMode = prev
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Failed to update Development Mode")
        }
    }
}
