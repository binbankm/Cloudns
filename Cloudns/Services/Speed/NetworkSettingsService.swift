import Foundation

/// Protocol defining Cloudflare network protocol and connectivity options service
protocol NetworkSettingsServiceProtocol: Sendable {
    func getNetworkSettings(zoneId: String) async throws -> NetworkSettings
    func updateIPv6(zoneId: String, isOn: Bool) async throws
    func updateWebsockets(zoneId: String, isOn: Bool) async throws
    func updateHTTP2(zoneId: String, isOn: Bool) async throws
    func updateHTTP3(zoneId: String, isOn: Bool) async throws
    func updateIPGeolocation(zoneId: String, isOn: Bool) async throws
    func updateOriginMaxHTTPVersion(zoneId: String, version: String) async throws
    func getSecurityHeader(zoneId: String) async throws -> HSTSSettings
    func updateSecurityHeader(zoneId: String, enabled: Bool, maxAge: Int, includeSubdomains: Bool, preload: Bool, nosniff: Bool) async throws
    func updateZeroRTT(zoneId: String, isOn: Bool) async throws
    func updatePseudoIPv4(zoneId: String, value: String) async throws
}

/// Concrete domain service for Cloudflare network protocols
final class NetworkSettingsService: NetworkSettingsServiceProtocol {
    static let shared = NetworkSettingsService()

    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared

    private init() {}

    func getNetworkSettings(zoneId: String) async throws -> NetworkSettings {
        async let v6 = try? getSetting(zoneId: zoneId, settingName: "ipv6")
        async let ws = try? getSetting(zoneId: zoneId, settingName: "websockets")
        async let h2 = try? getSetting(zoneId: zoneId, settingName: "http2")
        async let h3 = try? getSetting(zoneId: zoneId, settingName: "http3")
        async let geo = try? getSetting(zoneId: zoneId, settingName: "ip_geolocation")
        async let om = try? getSetting(zoneId: zoneId, settingName: "origin_max_http_version")
        let (ipv6, websockets, http2, http3, ipGeo, originMax) = await (v6, ws, h2, h3, geo, om)

        return NetworkSettings(
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

    func getSecurityHeader(zoneId: String) async throws -> HSTSSettings {
        let setting = try? await ZoneService.shared.getZoneSetting(zoneId: zoneId, settingName: "security_header")
        guard let s = setting, let hstsVal = s.value.securityHeaderValue?.strict_transport_security else {
            return HSTSSettings(enabled: false, maxAge: 0, includeSubdomains: false, nosniff: false, preload: false)
        }
        return HSTSSettings(
            enabled: hstsVal.enabled,
            maxAge: hstsVal.max_age,
            includeSubdomains: hstsVal.include_subdomains,
            nosniff: hstsVal.nosniff,
            preload: hstsVal.preload ?? false
        )
    }

    func updateSecurityHeader(zoneId: String, enabled: Bool, maxAge: Int, includeSubdomains: Bool, preload: Bool, nosniff: Bool) async throws {
        try await SSLSettingsService.shared.updateHSTS(
            zoneId: zoneId,
            enabled: enabled,
            maxAge: maxAge,
            subdomains: includeSubdomains,
            nosniff: nosniff,
            preload: preload
        )
    }

    /// Updates 0-RTT Connection Resumption setting (PATCH /zones/{zone_id}/settings/0rtt)
    func updateZeroRTT(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "0rtt", value: isOn ? "on" : "off")
    }

    /// Updates Pseudo IPv4 setting (PATCH /zones/{zone_id}/settings/pseudo_ipv4)
    func updatePseudoIPv4(zoneId: String, value: String) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "pseudo_ipv4", value: value)
    }

    private func getSetting(zoneId: String, settingName: String) async throws -> ZoneSetting? {
        try await ZoneService.shared.getZoneSetting(zoneId: zoneId, settingName: settingName)
    }

    private func updateSetting(zoneId: String, settingName: String, value: Any) async throws -> ZoneSetting {
        try await ZoneService.shared.updateZoneSetting(zoneId: zoneId, settingName: settingName, value: value)
    }
}
