import Foundation
import SwiftUI
import Combine

@MainActor
class CachingViewModel: BaseLoadableViewModel {
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
        isLoading = true
        errorMessage = nil
        
        do {
            let res = try await cachingService.getCachingSettings(zoneId: zoneId)
            self.cacheLevel = res.cacheLevel
            self.browserCacheTTL = res.browserTTL
            self.alwaysOnline = res.alwaysOnline
            self.developmentMode = res.devMode
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
            try await cachingService.purgeEverything(zoneId: zoneId)
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
            try await cachingService.purgeCacheByURLs(zoneId: zoneId, urls: urls)
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
            try await cachingService.purgeCacheByHosts(zoneId: zoneId, hosts: hosts)
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
            try await cachingService.purgeCacheByPrefixes(zoneId: zoneId, prefixes: prefixes)
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
            try await cachingService.purgeCacheByTags(zoneId: zoneId, tags: tags)
            purgeSuccessMessage = "Successfully purged requested Cache-Tags!"
            ToastManager.shared.showSuccess("Tags Purged", message: "\(tags.count) tag(s) purged from cache.")
        } catch {
            purgeErrorMessage = "Failed to purge tags: \(error.localizedDescription)"
            ToastManager.shared.showError("Purge Tags Failed", message: error.localizedDescription)
        }
        
        isPurging = false
    }
    
    func updateCacheLevel(zoneId: String, level: String) async {
        do {
            try await cachingService.updateCacheLevel(zoneId: zoneId, level: level)
            self.cacheLevel = level
        } catch {
            self.errorMessage = "Failed to update cache level: \(error.localizedDescription)"
        }
    }
    
    func updateBrowserCacheTTL(zoneId: String, ttl: Int) async {
        do {
            try await cachingService.updateBrowserCacheTTL(zoneId: zoneId, ttl: ttl)
            self.browserCacheTTL = ttl
        } catch {
            self.errorMessage = "Failed to update Browser Cache TTL: \(error.localizedDescription)"
        }
    }
    
    func updateAlwaysOnline(zoneId: String, isOn: Bool) async {
        do {
            try await cachingService.updateAlwaysOnline(zoneId: zoneId, isOn: isOn)
            self.alwaysOnline = isOn
        } catch {
            self.errorMessage = "Failed to update Always Online: \(error.localizedDescription)"
        }
    }
    
    func updateDevelopmentMode(zoneId: String, isOn: Bool) async {
        do {
            try await cachingService.updateDevelopmentMode(zoneId: zoneId, isOn: isOn)
            self.developmentMode = isOn
            NotificationCenter.default.post(name: .zoneUpdated, object: nil)
        } catch {
            self.errorMessage = "Failed to update Development Mode: \(error.localizedDescription)"
        }
    }
}
