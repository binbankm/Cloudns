import Foundation

private struct PurgeCacheResponse: Codable, Sendable {
    let id: String?
}

/// Protocol defining Cloudflare edge cache and purge domain service
protocol CachingServiceProtocol: Sendable {
    func getCachingSettings(zoneId: String) async throws -> CachingSettings
    func updateCacheLevel(zoneId: String, level: String) async throws
    func updateBrowserCacheTTL(zoneId: String, ttl: Int) async throws
    func updateAlwaysOnline(zoneId: String, isOn: Bool) async throws
    func updateDevelopmentMode(zoneId: String, isOn: Bool) async throws
    func purgeEverything(zoneId: String) async throws
    func purgeFiles(zoneId: String, files: [String]) async throws
    func purgeCacheByURLs(zoneId: String, urls: [String]) async throws
    func purgeCacheByHosts(zoneId: String, hosts: [String]) async throws
    func purgeCacheByPrefixes(zoneId: String, prefixes: [String]) async throws
    func purgeCacheByTags(zoneId: String, tags: [String]) async throws
    func getSmartTieredCache(zoneId: String) async throws -> Bool
    func updateSmartTieredCache(zoneId: String, enabled: Bool) async throws
}

/// Concrete domain service for Cloudflare edge cache management
final class CachingService: CachingServiceProtocol {
    static let shared = CachingService()

    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared

    private init() {}

    func getCachingSettings(zoneId: String) async throws -> CachingSettings {
        async let cl = try? getSetting(zoneId: zoneId, settingName: "cache_level")
        async let bt = try? getSetting(zoneId: zoneId, settingName: "browser_cache_ttl")
        async let ao = try? getSetting(zoneId: zoneId, settingName: "always_online")
        async let dm = try? getSetting(zoneId: zoneId, settingName: "development_mode")
        let (cacheLevel, browserTTL, alwaysOnline, devMode) = await (cl, bt, ao, dm)

        return CachingSettings(
            cacheLevel: cacheLevel?.value.stringValue ?? "aggressive",
            browserTTL: browserTTL?.value.intValue ?? 14400,
            alwaysOnline: alwaysOnline?.value.boolValue ?? true,
            developmentMode: devMode?.value.boolValue ?? false
        )
    }

    func updateCacheLevel(zoneId: String, level: String) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "cache_level", value: level)
    }

    func updateBrowserCacheTTL(zoneId: String, ttl: Int) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "browser_cache_ttl", value: ttl)
    }

    func updateAlwaysOnline(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "always_online", value: isOn ? "on" : "off")
    }

    func updateDevelopmentMode(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "development_mode", value: isOn ? "on" : "off")
    }

    func purgeEverything(zoneId: String) async throws {
        let payload = ["purge_everything": true]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/purge_cache", method: "POST", body: data)
        let (_, _): (PurgeCacheResponse?, ResultInfo?) = try await client.performRequest(request)
    }

    func purgeFiles(zoneId: String, files: [String]) async throws {
        let payload = ["files": files]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/purge_cache", method: "POST", body: data)
        let (_, _): (PurgeCacheResponse?, ResultInfo?) = try await client.performRequest(request)
    }

    func purgeCacheByURLs(zoneId: String, urls: [String]) async throws {
        try await purgeFiles(zoneId: zoneId, files: urls)
    }

    func purgeCacheByHosts(zoneId: String, hosts: [String]) async throws {
        let payload = ["hosts": hosts]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/purge_cache", method: "POST", body: data)
        let (_, _): (PurgeCacheResponse?, ResultInfo?) = try await client.performRequest(request)
    }

    func purgeCacheByPrefixes(zoneId: String, prefixes: [String]) async throws {
        let payload = ["prefixes": prefixes]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/purge_cache", method: "POST", body: data)
        let (_, _): (PurgeCacheResponse?, ResultInfo?) = try await client.performRequest(request)
    }

    func purgeCacheByTags(zoneId: String, tags: [String]) async throws {
        let payload = ["tags": tags]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/purge_cache", method: "POST", body: data)
        let (_, _): (PurgeCacheResponse?, ResultInfo?) = try await client.performRequest(request)
    }

    /// Fetches Smart Tiered Cache status (GET /zones/{zone_id}/cache/tiered_cache_smart_topology_enable)
    func getSmartTieredCache(zoneId: String) async throws -> Bool {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/cache/tiered_cache_smart_topology_enable")
        struct SmartTopologyRes: Codable {
            let value: String?
        }
        let (res, _): (SmartTopologyRes?, ResultInfo?) = try await client.performRequest(request)
        return (res?.value ?? "off").lowercased() == "on"
    }

    /// Updates Smart Tiered Cache status (PATCH /zones/{zone_id}/cache/tiered_cache_smart_topology_enable)
    func updateSmartTieredCache(zoneId: String, enabled: Bool) async throws {
        let payload = ["value": enabled ? "on" : "off"]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(
            path: "zones/\(zoneId)/cache/tiered_cache_smart_topology_enable",
            method: "PATCH",
            body: data
        )
        struct Res: Codable { let value: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }

    // MARK: - Centralized Zone Setting Delegation

    private func getSetting(zoneId: String, settingName: String) async throws -> ZoneSetting? {
        try await ZoneService.shared.getZoneSetting(zoneId: zoneId, settingName: settingName)
    }

    private func updateSetting(zoneId: String, settingName: String, value: Any) async throws -> ZoneSetting {
        try await ZoneService.shared.updateZoneSetting(zoneId: zoneId, settingName: settingName, value: value)
    }
}
