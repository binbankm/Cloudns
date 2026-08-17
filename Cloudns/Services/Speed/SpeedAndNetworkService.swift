import Foundation

/// 统一的 Cloudflare 速度优化、网络协议与缓存管理领域服务
final class SpeedAndNetworkService {
    static let shared = SpeedAndNetworkService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    // MARK: - Speed Settings
    
    func getSpeedSettings(zoneId: String) async throws -> (minifyCSS: Bool, minifyHTML: Bool, minifyJS: Bool, brotli: Bool, rocketLoader: Bool, earlyHints: Bool) {
        async let min = getSetting(zoneId: zoneId, settingName: "minify")
        async let br = getSetting(zoneId: zoneId, settingName: "brotli")
        async let rl = getSetting(zoneId: zoneId, settingName: "rocket_loader")
        async let eh = getSetting(zoneId: zoneId, settingName: "early_hints")
        
        let (minify, brotli, rocket, hints) = try await (min, br, rl, eh)
        
        var css = false, html = false, js = false
        if let dict = minify?.value as? [String: String] {
            css = (dict["css"] == "on")
            html = (dict["html"] == "on")
            js = (dict["js"] == "on")
        }
        
        return (
            minifyCSS: css,
            minifyHTML: html,
            minifyJS: js,
            brotli: ((brotli?.value as? String) ?? "off") == "on",
            rocketLoader: ((rocket?.value as? String) ?? "off") == "on",
            earlyHints: ((hints?.value as? String) ?? "off") == "on"
        )
    }
    
    func updateMinify(zoneId: String, css: Bool, html: Bool, js: Bool) async throws {
        let valueDict = [
            "css": css ? "on" : "off",
            "html": html ? "on" : "off",
            "js": js ? "on" : "off"
        ]
        _ = try await updateSetting(zoneId: zoneId, settingName: "minify", value: valueDict)
    }
    
    func updateBrotli(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "brotli", value: isOn ? "on" : "off")
    }
    
    func updateRocketLoader(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "rocket_loader", value: isOn ? "on" : "off")
    }
    
    func updateEarlyHints(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "early_hints", value: isOn ? "on" : "off")
    }
    
    // MARK: - Network Settings
    
    func getNetworkSettings(zoneId: String) async throws -> (ipv6: Bool, websockets: Bool, http2: Bool, http3: Bool, ipGeolocation: Bool) {
        async let v6 = getSetting(zoneId: zoneId, settingName: "ipv6")
        async let ws = getSetting(zoneId: zoneId, settingName: "websockets")
        async let h2 = getSetting(zoneId: zoneId, settingName: "http2")
        async let h3 = getSetting(zoneId: zoneId, settingName: "http3")
        async let geo = getSetting(zoneId: zoneId, settingName: "ip_geolocation")
        
        let (ipv6, websockets, http2, http3, ipGeo) = try await (v6, ws, h2, h3, geo)
        
        return (
            ipv6: ((ipv6?.value as? String) ?? "off") == "on",
            websockets: ((websockets?.value as? String) ?? "off") == "on",
            http2: ((http2?.value as? String) ?? "off") == "on",
            http3: ((http3?.value as? String) ?? "off") == "on",
            ipGeolocation: ((ipGeo?.value as? String) ?? "off") == "on"
        )
    }
    
    func updateIPv6(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "ipv6", value: isOn ? "on" : "off")
    }
    
    func updateWebsockets(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "websockets", value: isOn ? "on" : "off")
    }
    
    func updateHTTP2(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "http2", value: isOn ? "on" : "off")
    }
    
    func updateHTTP3(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "http3", value: isOn ? "on" : "off")
    }
    
    func updateIPGeolocation(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "ip_geolocation", value: isOn ? "on" : "off")
    }
    
    // MARK: - Caching Settings & Granular Purge
    
    func getCachingSettings(zoneId: String) async throws -> (cacheLevel: String, browserTTL: Int, alwaysOnline: Bool, devMode: Bool) {
        async let cl = getSetting(zoneId: zoneId, settingName: "cache_level")
        async let bt = getSetting(zoneId: zoneId, settingName: "browser_cache_ttl")
        async let ao = getSetting(zoneId: zoneId, settingName: "always_online")
        async let dm = getSetting(zoneId: zoneId, settingName: "development_mode")
        
        let (cacheLevel, browserTTL, alwaysOnline, devMode) = try await (cl, bt, ao, dm)
        
        return (
            cacheLevel: (cacheLevel?.value as? String) ?? "aggressive",
            browserTTL: (browserTTL?.value as? Int) ?? 14400,
            alwaysOnline: ((alwaysOnline?.value as? String) ?? "off") == "on",
            devMode: ((devMode?.value as? String) ?? "off") == "on"
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
        struct PurgeRes: Codable { let id: String? }
        let (_, _): (PurgeRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func purgeFiles(zoneId: String, files: [String]) async throws {
        let payload = ["files": files]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/purge_cache", method: "POST", body: data)
        struct PurgeRes: Codable { let id: String? }
        let (_, _): (PurgeRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func purgeCacheByURLs(zoneId: String, urls: [String]) async throws {
        try await purgeFiles(zoneId: zoneId, files: urls)
    }
    
    func purgeCacheByHosts(zoneId: String, hosts: [String]) async throws {
        let payload = ["hosts": hosts]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/purge_cache", method: "POST", body: data)
        struct PurgeRes: Codable { let id: String? }
        let (_, _): (PurgeRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func purgeCacheByPrefixes(zoneId: String, prefixes: [String]) async throws {
        let payload = ["prefixes": prefixes]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/purge_cache", method: "POST", body: data)
        struct PurgeRes: Codable { let id: String? }
        let (_, _): (PurgeRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func purgeCacheByTags(zoneId: String, tags: [String]) async throws {
        let payload = ["tags": tags]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/purge_cache", method: "POST", body: data)
        struct PurgeRes: Codable { let id: String? }
        let (_, _): (PurgeRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    // MARK: - Generic Setting Helpers
    
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
