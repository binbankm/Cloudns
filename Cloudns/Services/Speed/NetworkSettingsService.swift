import Foundation

/// Cloudflare 边缘网络协议与连接选项服务协议
protocol NetworkSettingsServiceProtocol: Sendable {
    func getNetworkSettings(zoneId: String) async throws -> (ipv6: Bool, websockets: Bool, http2: Bool, http3: Bool, ipGeolocation: Bool, originMaxHttpVersion: String)
    func updateIPv6(zoneId: String, isOn: Bool) async throws
    func updateWebsockets(zoneId: String, isOn: Bool) async throws
    func updateHTTP2(zoneId: String, isOn: Bool) async throws
    func updateHTTP3(zoneId: String, isOn: Bool) async throws
    func updateIPGeolocation(zoneId: String, isOn: Bool) async throws
    func updateOriginMaxHTTPVersion(zoneId: String, version: String) async throws
    func getSecurityHeader(zoneId: String) async throws -> (enabled: Bool, maxAge: Int, includeSubdomains: Bool, preload: Bool, nosniff: Bool)
    func updateSecurityHeader(zoneId: String, enabled: Bool, maxAge: Int, includeSubdomains: Bool, preload: Bool, nosniff: Bool) async throws
}

/// 统一的 Cloudflare 边缘网络协议领域服务
final class NetworkSettingsService: NetworkSettingsServiceProtocol {
    static let shared = NetworkSettingsService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func getNetworkSettings(zoneId: String) async throws -> (ipv6: Bool, websockets: Bool, http2: Bool, http3: Bool, ipGeolocation: Bool, originMaxHttpVersion: String) {
        async let v6 = try? getSetting(zoneId: zoneId, settingName: "ipv6")
        async let ws = try? getSetting(zoneId: zoneId, settingName: "websockets")
        async let h2 = try? getSetting(zoneId: zoneId, settingName: "http2")
        async let h3 = try? getSetting(zoneId: zoneId, settingName: "http3")
        async let geo = try? getSetting(zoneId: zoneId, settingName: "ip_geolocation")
        async let om = try? getSetting(zoneId: zoneId, settingName: "origin_max_http_version")
        let (ipv6, websockets, http2, http3, ipGeo, originMax) = await (v6, ws, h2, h3, geo, om)
        
        return (
            ipv6: (ipv6?.value.stringValue ?? "off") == "on",
            websockets: (websockets?.value.stringValue ?? "off") == "on",
            http2: (http2?.value.stringValue ?? "off") == "on",
            http3: (http3?.value.stringValue ?? "off") == "on",
            ipGeolocation: (ipGeo?.value.stringValue ?? "off") == "on",
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
    
    func getSecurityHeader(zoneId: String) async throws -> (enabled: Bool, maxAge: Int, includeSubdomains: Bool, preload: Bool, nosniff: Bool) {
        let setting = try? await getSetting(zoneId: zoneId, settingName: "security_header")
        guard let s = setting else {
            return (enabled: false, maxAge: 0, includeSubdomains: false, preload: false, nosniff: false)
        }
        return (
            enabled: s.value.boolValue,
            maxAge: 0,
            includeSubdomains: false,
            preload: false,
            nosniff: false
        )
    }
    
    func updateSecurityHeader(zoneId: String, enabled: Bool, maxAge: Int, includeSubdomains: Bool, preload: Bool, nosniff: Bool) async throws {
        let payload: [String: Any] = [
            "value": [
                "strict_transport_security": [
                    "enabled": enabled,
                    "max_age": maxAge,
                    "include_subdomains": includeSubdomains,
                    "preload": preload,
                    "nosniff": nosniff
                ]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/settings/security_header", method: "PATCH", body: data)
        let (_, _): (ZoneSetting?, ResultInfo?) = try await client.performRequest(request)
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
