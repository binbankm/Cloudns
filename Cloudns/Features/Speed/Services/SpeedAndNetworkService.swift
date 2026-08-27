import Foundation

/// Cloudflare 速度优化、网络协议与缓存管理领域服务抽象协议
protocol SpeedAndNetworkServiceProtocol: Sendable {
    func getSpeedSettings(zoneId: String) async throws -> (brotli: Bool, rocketLoader: Bool, earlyHints: Bool, speedBrain: Bool, fonts: Bool, tieredCache: Bool, polish: String)
    func updateBrotli(zoneId: String, isOn: Bool) async throws
    func updateRocketLoader(zoneId: String, isOn: Bool) async throws
    func updateEarlyHints(zoneId: String, isOn: Bool) async throws
    func updateSpeedBrain(zoneId: String, isOn: Bool) async throws
    func updateFonts(zoneId: String, isOn: Bool) async throws
    func updateTieredCache(zoneId: String, isOn: Bool) async throws
    func updatePolish(zoneId: String, value: String) async throws
    func getNetworkSettings(zoneId: String) async throws -> (ipv6: Bool, websockets: Bool, http2: Bool, http3: Bool, ipGeolocation: Bool, originMaxHttpVersion: String)
    func updateIPv6(zoneId: String, isOn: Bool) async throws
    func updateWebsockets(zoneId: String, isOn: Bool) async throws
    func updateHTTP2(zoneId: String, isOn: Bool) async throws
    func updateHTTP3(zoneId: String, isOn: Bool) async throws
    func updateIPGeolocation(zoneId: String, isOn: Bool) async throws
    func updateOriginMaxHTTPVersion(zoneId: String, version: String) async throws
    func getCachingSettings(zoneId: String) async throws -> (cacheLevel: String, browserTTL: Int, alwaysOnline: Bool, devMode: Bool)
    func updateCacheLevel(zoneId: String, level: String) async throws
    func updateBrowserCacheTTL(zoneId: String, ttl: Int) async throws
    func updateAlwaysOnline(zoneId: String, isOn: Bool) async throws
    func updateDevelopmentMode(zoneId: String, isOn: Bool) async throws
    func getSecurityHeader(zoneId: String) async throws -> (enabled: Bool, maxAge: Int, includeSubdomains: Bool, preload: Bool, nosniff: Bool)
    func updateSecurityHeader(zoneId: String, enabled: Bool, maxAge: Int, includeSubdomains: Bool, preload: Bool, nosniff: Bool) async throws
    func purgeEverything(zoneId: String) async throws
    func purgeFiles(zoneId: String, files: [String]) async throws
    func purgeCacheByURLs(zoneId: String, urls: [String]) async throws
    func purgeCacheByHosts(zoneId: String, hosts: [String]) async throws
    func purgeCacheByPrefixes(zoneId: String, prefixes: [String]) async throws
    func purgeCacheByTags(zoneId: String, tags: [String]) async throws
}

/// 统一的 Cloudflare 速度优化、网络协议与缓存管理领域服务
final class SpeedAndNetworkService: SpeedAndNetworkServiceProtocol {
    // MARK: - Lifecycle & Dependencies
     = SpeedAndNetworkService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    // MARK: - Speed Settings
    
    func getSpeedSettings(zoneId: String) async throws -> (brotli: Bool, rocketLoader: Bool, earlyHints: Bool, speedBrain: Bool, fonts: Bool, tieredCache: Bool, polish: String) {
        let allSettings = (try? await fetchZoneSettings(zoneId: zoneId)) ?? []
        
        var brotli: ZoneSetting?
        var rocket: ZoneSetting?
        var hints: ZoneSetting?
        var speedBrain: ZoneSetting?
        var fonts: ZoneSetting?
        var polish: ZoneSetting?
        
        if !allSettings.isEmpty {
            brotli = allSettings.first(where: { $0.id == "brotli" })
            rocket = allSettings.first(where: { $0.id == "rocket_loader" })
            hints = allSettings.first(where: { $0.id == "early_hints" })
            speedBrain = allSettings.first(where: { $0.id == "speed_brain" })
            fonts = allSettings.first(where: { $0.id == "fonts" })
            polish = allSettings.first(where: { $0.id == "polish" })
        } else {
            async let br = try? getSetting(zoneId: zoneId, settingName: "brotli")
            async let rl = try? getSetting(zoneId: zoneId, settingName: "rocket_loader")
            async let eh = try? getSetting(zoneId: zoneId, settingName: "early_hints")
            async let sb = try? getSetting(zoneId: zoneId, settingName: "speed_brain")
            async let fn = try? getSetting(zoneId: zoneId, settingName: "fonts")
            async let pl = try? getSetting(zoneId: zoneId, settingName: "polish")
            let (b, r, h, s, f, p) = await (br, rl, eh, sb, fn, pl)
            brotli = b
            rocket = r
            hints = h
            speedBrain = s
            fonts = f
            polish = p
        }
        
        // Tiered cache query (via argo/tiered_caching or tiered_cache)
        let tieredCacheOn = await getTieredCacheStatus(zoneId: zoneId)
        
        return (
            brotli: brotli?.value.boolValue ?? false,
            rocketLoader: rocket?.value.boolValue ?? false,
            earlyHints: hints?.value.boolValue ?? false,
            speedBrain: speedBrain?.value.boolValue ?? false,
            fonts: fonts?.value.boolValue ?? false,
            tieredCache: tieredCacheOn,
            polish: polish?.value.stringValue ?? "off"
        )
    }
    
    private func getTieredCacheStatus(zoneId: String) async -> Bool {
        do {
            let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/argo/tiered_caching")
            struct TieredRes: Codable {
                let id: String?
                let value: String?
                let editable: Bool?
            }
            let (res, _): (TieredRes?, ResultInfo?) = try await client.performRequest(request)
            return res?.value?.lowercased() == "on"
        } catch {
            return false
        }
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
    
    func updateSpeedBrain(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "speed_brain", value: isOn ? "on" : "off")
    }
    
    func updateFonts(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "fonts", value: isOn ? "on" : "off")
    }
    
    func updateTieredCache(zoneId: String, isOn: Bool) async throws {
        let payload = ["value": isOn ? "on" : "off"]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/argo/tiered_caching", method: "PATCH", body: data)
        struct TieredRes: Codable { let value: String? }
        let (_, _): (TieredRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func updatePolish(zoneId: String, value: String) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "polish", value: value)
    }
    
    // MARK: - Network Settings
    
    func getNetworkSettings(zoneId: String) async throws -> (ipv6: Bool, websockets: Bool, http2: Bool, http3: Bool, ipGeolocation: Bool, originMaxHttpVersion: String) {
        let allSettings = (try? await fetchZoneSettings(zoneId: zoneId)) ?? []
        
        var ipv6: ZoneSetting?
        var websockets: ZoneSetting?
        var http2: ZoneSetting?
        var http3: ZoneSetting?
        var ipGeo: ZoneSetting?
        var originMax: ZoneSetting?
        
        if !allSettings.isEmpty {
            ipv6 = allSettings.first(where: { $0.id == "ipv6" })
            websockets = allSettings.first(where: { $0.id == "websockets" })
            http2 = allSettings.first(where: { $0.id == "http2" })
            http3 = allSettings.first(where: { $0.id == "http3" })
            ipGeo = allSettings.first(where: { $0.id == "ip_geolocation" })
            originMax = allSettings.first(where: { $0.id == "origin_max_http_version" })
        } else {
            async let v6 = try? getSetting(zoneId: zoneId, settingName: "ipv6")
            async let ws = try? getSetting(zoneId: zoneId, settingName: "websockets")
            async let h2 = try? getSetting(zoneId: zoneId, settingName: "http2")
            async let h3 = try? getSetting(zoneId: zoneId, settingName: "http3")
            async let geo = try? getSetting(zoneId: zoneId, settingName: "ip_geolocation")
            async let om = try? getSetting(zoneId: zoneId, settingName: "origin_max_http_version")
            let (v, w, h2Res, h3Res, g, omRes) = await (v6, ws, h2, h3, geo, om)
            ipv6 = v
            websockets = w
            http2 = h2Res
            http3 = h3Res
            ipGeo = g
            originMax = omRes
        }
        
        return (
            ipv6: ipv6?.value.boolValue ?? false,
            websockets: websockets?.value.boolValue ?? false,
            http2: http2?.value.boolValue ?? false,
            http3: http3?.value.boolValue ?? false,
            ipGeolocation: ipGeo?.value.boolValue ?? false,
            originMaxHttpVersion: originMax?.value.stringValue ?? "2"
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
    
    func updateOriginMaxHTTPVersion(zoneId: String, version: String) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "origin_max_http_version", value: version)
    }
    
    // MARK: - Security Header (HSTS)
    
    func getSecurityHeader(zoneId: String) async throws -> (enabled: Bool, maxAge: Int, includeSubdomains: Bool, preload: Bool, nosniff: Bool) {
        let setting = try await getSetting(zoneId: zoneId, settingName: "security_header")
        guard let hsts = setting?.value.securityHeaderValue?.strict_transport_security else {
            return (enabled: false, maxAge: 31536000, includeSubdomains: false, preload: false, nosniff: false)
        }
        return (hsts.enabled, hsts.max_age, hsts.include_subdomains, hsts.preload ?? false, hsts.nosniff)
    }
    
    func updateSecurityHeader(zoneId: String, enabled: Bool, maxAge: Int, includeSubdomains: Bool, preload: Bool, nosniff: Bool) async throws {
        let hstsDict: [String: Any] = [
            "strict_transport_security": [
                "enabled": enabled,
                "max_age": maxAge,
                "include_subdomains": includeSubdomains,
                "preload": preload,
                "nosniff": nosniff
            ]
        ]
        _ = try await updateSetting(zoneId: zoneId, settingName: "security_header", value: hstsDict)
    }
    
    // MARK: - Caching Settings & Granular Purge
    
    func getCachingSettings(zoneId: String) async throws -> (cacheLevel: String, browserTTL: Int, alwaysOnline: Bool, devMode: Bool) {
        let allSettings = (try? await fetchZoneSettings(zoneId: zoneId)) ?? []
        
        var cacheLevel: ZoneSetting?
        var browserTTL: ZoneSetting?
        var alwaysOnline: ZoneSetting?
        var devMode: ZoneSetting?
        
        if !allSettings.isEmpty {
            cacheLevel = allSettings.first(where: { $0.id == "cache_level" })
            browserTTL = allSettings.first(where: { $0.id == "browser_cache_ttl" })
            alwaysOnline = allSettings.first(where: { $0.id == "always_online" })
            devMode = allSettings.first(where: { $0.id == "development_mode" })
        } else {
            async let cl = try? getSetting(zoneId: zoneId, settingName: "cache_level")
            async let bt = try? getSetting(zoneId: zoneId, settingName: "browser_cache_ttl")
            async let ao = try? getSetting(zoneId: zoneId, settingName: "always_online")
            async let dm = try? getSetting(zoneId: zoneId, settingName: "development_mode")
            let (c, b, a, d) = await (cl, bt, ao, dm)
            cacheLevel = c
            browserTTL = b
            alwaysOnline = a
            devMode = d
        }
        
        return (
            cacheLevel: cacheLevel?.value.stringValue ?? "aggressive",
            browserTTL: browserTTL?.value.intValue ?? 14400,
            alwaysOnline: alwaysOnline?.value.boolValue ?? false,
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
    
    private func fetchZoneSettings(zoneId: String) async throws -> [ZoneSetting] {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/settings")
        let (settings, _): ([ZoneSetting]?, ResultInfo?) = try await client.performRequest(request)
        return settings ?? []
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
