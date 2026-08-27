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
            CloudnsToastManager.shared.showSuccess("Cache Purged", message: "All cached resources were purged successfully.")
        } catch {
            purgeErrorMessage = "Failed to purge cache: \(error.localizedDescription)"
            CloudnsToastManager.shared.showError("Purge Cache Failed", message: error.localizedDescription)
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
            CloudnsToastManager.shared.showSuccess("URLs Purged", message: "\(urls.count) URL(s) purged from cache.")
        } catch {
            purgeErrorMessage = "Failed to purge URLs: \(error.localizedDescription)"
            CloudnsToastManager.shared.showError("Purge URLs Failed", message: error.localizedDescription)
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
            CloudnsToastManager.shared.showSuccess("Hosts Purged", message: "\(hosts.count) host(s) purged from cache.")
        } catch {
            purgeErrorMessage = "Failed to purge hosts: \(error.localizedDescription)"
            CloudnsToastManager.shared.showError("Purge Hosts Failed", message: error.localizedDescription)
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
            CloudnsToastManager.shared.showSuccess("Prefixes Purged", message: "\(prefixes.count) prefix(es) purged from cache.")
        } catch {
            purgeErrorMessage = "Failed to purge prefixes: \(error.localizedDescription)"
            CloudnsToastManager.shared.showError("Purge Prefixes Failed", message: error.localizedDescription)
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
            CloudnsToastManager.shared.showSuccess("Tags Purged", message: "\(tags.count) tag(s) purged from cache.")
        } catch {
            purgeErrorMessage = "Failed to purge tags: \(error.localizedDescription)"
            CloudnsToastManager.shared.showError("Purge Tags Failed", message: error.localizedDescription)
        }
        
        isPurging = false
    }
    
    func updateCacheLevel(zoneId: String, level: String) async {
        let prev = self.cacheLevel
        self.cacheLevel = level
        do {
            try await cachingService.updateCacheLevel(zoneId: zoneId, level: level)
            CloudnsToastManager.shared.showSuccess("Caching Level", message: "Updated to \(level.capitalized)")
        } catch {
            self.cacheLevel = prev
            self.errorMessage = error.localizedDescription
            CloudnsToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func updateBrowserCacheTTL(zoneId: String, ttl: Int) async {
        let prev = self.browserCacheTTL
        self.browserCacheTTL = ttl
        do {
            try await cachingService.updateBrowserCacheTTL(zoneId: zoneId, ttl: ttl)
            CloudnsToastManager.shared.showSuccess("Browser Cache TTL", message: "TTL updated successfully.")
        } catch {
            self.browserCacheTTL = prev
            self.errorMessage = error.localizedDescription
            CloudnsToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func updateAlwaysOnline(zoneId: String, isOn: Bool) async {
        let prev = self.alwaysOnline
        self.alwaysOnline = isOn
        do {
            try await cachingService.updateAlwaysOnline(zoneId: zoneId, isOn: isOn)
            CloudnsToastManager.shared.showSuccess("Always Online", message: isOn ? "Enabled" : "Disabled")
        } catch {
            self.alwaysOnline = prev
            self.errorMessage = error.localizedDescription
            CloudnsToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func updateDevelopmentMode(zoneId: String, isOn: Bool) async {
        let prev = self.developmentMode
        self.developmentMode = isOn
        do {
            try await cachingService.updateDevelopmentMode(zoneId: zoneId, isOn: isOn)
            await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("zone_details_\(zoneId)"))
            CloudnsToastManager.shared.showSuccess("Development Mode", message: isOn ? "Enabled (3 hours)" : "Disabled")
            NotificationCenter.default.post(name: .zoneUpdated, object: nil, userInfo: ["zoneId": zoneId])
        } catch {
            self.developmentMode = prev
            self.errorMessage = error.localizedDescription
            CloudnsToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
}
