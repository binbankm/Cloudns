import Combine
import Foundation

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

    private let cachingService: CachingServiceProtocol

    init(cachingService: CachingServiceProtocol = CachingService.shared) {
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
            purgeSuccessMessage = String(localized: "All cache successfully purged.")
        } catch {
            purgeErrorMessage = "Failed to purge cache: \(error.localizedDescription)"
        }

        isPurging = false
    }

    func purgeCacheByURLs(zoneId: String, urls: [String]) async {
        isPurging = true
        purgeSuccessMessage = nil
        purgeErrorMessage = nil

        do {
            try await cachingService.purgeCacheByURLs(zoneId: zoneId, urls: urls)
            purgeSuccessMessage = String(localized: "Requested URLs successfully purged.")
        } catch {
            purgeErrorMessage = "Failed to purge URLs: \(error.localizedDescription)"
        }

        isPurging = false
    }

    func purgeCacheByHosts(zoneId: String, hosts: [String]) async {
        isPurging = true
        purgeSuccessMessage = nil
        purgeErrorMessage = nil

        do {
            try await cachingService.purgeCacheByHosts(zoneId: zoneId, hosts: hosts)
            purgeSuccessMessage = String(localized: "Requested hosts successfully purged.")
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
            purgeSuccessMessage = String(localized: "Requested URL prefixes successfully purged.")
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
            purgeSuccessMessage = String(localized: "Requested Cache-Tags successfully purged.")
        } catch {
            purgeErrorMessage = "Failed to purge tags: \(error.localizedDescription)"
        }

        isPurging = false
    }

    func updateCacheLevel(zoneId: String, level: String) async {
        let prev = cacheLevel
        cacheLevel = level
        do {
            try await cachingService.updateCacheLevel(zoneId: zoneId, level: level)
        } catch {
            cacheLevel = prev
            errorMessage = error.localizedDescription
        }
    }

    func updateBrowserCacheTTL(zoneId: String, ttl: Int) async {
        let prev = browserCacheTTL
        browserCacheTTL = ttl
        do {
            try await cachingService.updateBrowserCacheTTL(zoneId: zoneId, ttl: ttl)
        } catch {
            browserCacheTTL = prev
            errorMessage = error.localizedDescription
        }
    }

    func updateAlwaysOnline(zoneId: String, isOn: Bool) async {
        let prev = alwaysOnline
        alwaysOnline = isOn
        do {
            try await cachingService.updateAlwaysOnline(zoneId: zoneId, isOn: isOn)
        } catch {
            alwaysOnline = prev
            errorMessage = error.localizedDescription
        }
    }

    func updateDevelopmentMode(zoneId: String, isOn: Bool) async {
        let prev = developmentMode
        developmentMode = isOn
        do {
            try await cachingService.updateDevelopmentMode(zoneId: zoneId, isOn: isOn)
            await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("zone_details_\(zoneId)"))
            NotificationCenter.default.post(name: .zoneUpdated, object: nil, userInfo: ["zoneId": zoneId])
        } catch {
            developmentMode = prev
            errorMessage = error.localizedDescription
        }
    }
}
