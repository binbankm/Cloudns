import Foundation

private struct PurgeCacheResponse: Codable, Sendable {
    let id: String?
}

/// Cloudflare 边缘缓存与清理领域服务协议
protocol CachingServiceProtocol: Sendable {
    func getCachingSettings(zoneId: String) async throws -> (cacheLevel: String, browserTTL: Int, alwaysOnline: Bool, devMode: Bool)
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
}

/// 统一的 Cloudflare 边缘缓存领域服务
final class CachingService: CachingServiceProtocol {
    static let shared = CachingService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func getCachingSettings(zoneId: String) async throws -> (cacheLevel: String, browserTTL: Int, alwaysOnline: Bool, devMode: Bool) {
        async let cl = try? getSetting(zoneId: zoneId, settingName: "cache_level")
        async let bt = try? getSetting(zoneId: zoneId, settingName: "browser_cache_ttl")
        async let ao = try? getSetting(zoneId: zoneId, settingName: "always_online")
        async let dm = try? getSetting(zoneId: zoneId, settingName: "development_mode")
        let (cacheLevel, browserTTL, alwaysOnline, devMode) = await (cl, bt, ao, dm)
        
        return (
            cacheLevel: cacheLevel?.value.stringValue ?? "aggressive",
            browserTTL: browserTTL?.value.intValue ?? 14400,
            alwaysOnline: alwaysOnline?.value.boolValue ?? true,
            devMode: devMode?.value.boolValue ?? false
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
    
    private func getSetting(zoneId: String, settingName: String) async throws -> ZoneSetting? {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/settings/\(settingName)")
        let (setting, _): (ZoneSetting?, ResultInfo?) = try await client.performRequest(request)
        return setting
    }
    
    private func updateSetting(zoneId: String, settingName: String, value: Any) async throws -> ZoneSetting {
        let payload = ["value": value]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/settings/\(settingName)", method: "PATCH", body: data)
        let (setting, _): (ZoneSetting?, ResultInfo?) = try await client.performRequest(request)
        guard let s = setting else {
            throw APIError.cloudflareError("Failed to update \(settingName).")
        }
        return s
    }
}
