import Foundation

/// Protocol defining Cloudflare Zone SSL/TLS encryption and protocol settings
protocol SSLSettingsServiceProtocol: Sendable {
    func getSSLSettings(zoneId: String) async throws -> SSLSettings
    func updateSSLMode(zoneId: String, mode: String) async throws
    func updateAlwaysUseHTTPS(zoneId: String, isOn: Bool) async throws
    func updateAutomaticHTTPSRewrites(zoneId: String, isOn: Bool) async throws
    func updateMinTLSVersion(zoneId: String, version: String) async throws
    func updateTLS13(zoneId: String, isOn: Bool) async throws
    func updateOpportunisticEncryption(zoneId: String, isOn: Bool) async throws
    func updateOpportunisticOnion(zoneId: String, isOn: Bool) async throws
    func updateHSTS(zoneId: String, enabled: Bool, maxAge: Int, subdomains: Bool, nosniff: Bool, preload: Bool) async throws
}

/// Concrete domain service for Cloudflare SSL/TLS configuration
final class SSLSettingsService: SSLSettingsServiceProtocol {
    static let shared = SSLSettingsService()

    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared

    private init() {}

    func getSSLSettings(zoneId: String) async throws -> SSLSettings {
        let allSettings = await (try? ZoneService.shared.getZoneSettings(zoneId: zoneId)) ?? []

        var s: ZoneSetting?
        var h: ZoneSetting?
        var r: ZoneSetting?
        var mt: ZoneSetting?
        var t: ZoneSetting?
        var oe: ZoneSetting?
        var oo: ZoneSetting?
        var sh: ZoneSetting?

        if !allSettings.isEmpty {
            s = allSettings.first(where: { $0.id == "ssl" })
            h = allSettings.first(where: { $0.id == "always_use_https" })
            r = allSettings.first(where: { $0.id == "automatic_https_rewrites" })
            mt = allSettings.first(where: { $0.id == "min_tls_version" })
            t = allSettings.first(where: { $0.id == "tls_1_3" })
            oe = allSettings.first(where: { $0.id == "opportunistic_encryption" })
            oo = allSettings.first(where: { $0.id == "opportunistic_onion" })
            sh = allSettings.first(where: { $0.id == "security_header" })
        } else {
            async let ssl = try? ZoneService.shared.getZoneSetting(zoneId: zoneId, settingName: "ssl")
            async let https = try? ZoneService.shared.getZoneSetting(zoneId: zoneId, settingName: "always_use_https")
            async let rewrites = try? ZoneService.shared.getZoneSetting(zoneId: zoneId, settingName: "automatic_https_rewrites")
            async let minTLS = try? ZoneService.shared.getZoneSetting(zoneId: zoneId, settingName: "min_tls_version")
            async let tls13 = try? ZoneService.shared.getZoneSetting(zoneId: zoneId, settingName: "tls_1_3")
            async let oppEnc = try? ZoneService.shared.getZoneSetting(zoneId: zoneId, settingName: "opportunistic_encryption")
            async let oppOnion = try? ZoneService.shared.getZoneSetting(zoneId: zoneId, settingName: "opportunistic_onion")
            async let hsts = try? ZoneService.shared.getZoneSetting(zoneId: zoneId, settingName: "security_header")

            let (sslRes, httpsRes, rewritesRes, minTLSRes, tls13Res, oppEncRes, oppOnionRes, hstsRes) = await (ssl, https, rewrites, minTLS, tls13, oppEnc, oppOnion, hsts)
            s = sslRes
            h = httpsRes
            r = rewritesRes
            mt = minTLSRes
            t = tls13Res
            oe = oppEncRes
            oo = oppOnionRes
            sh = hstsRes
        }

        var hstsEnabled = false
        var hstsMaxAge = 2_592_000
        var hstsSubdomains = false
        var hstsNoSniff = false
        var hstsPreload = false

        if let hstsVal = sh?.value.securityHeaderValue?.strict_transport_security {
            hstsEnabled = hstsVal.enabled
            hstsMaxAge = hstsVal.max_age
            hstsSubdomains = hstsVal.include_subdomains
            hstsNoSniff = hstsVal.nosniff
            hstsPreload = hstsVal.preload ?? false
        }

        let hstsSettings = HSTSSettings(
            enabled: hstsEnabled,
            maxAge: hstsMaxAge,
            includeSubdomains: hstsSubdomains,
            nosniff: hstsNoSniff,
            preload: hstsPreload
        )

        return SSLSettings(
            sslMode: s?.value.stringValue ?? "off",
            alwaysUseHTTPS: h?.value.boolValue ?? false,
            automaticHTTPSRewrites: r?.value.boolValue ?? false,
            minTLSVersion: mt?.value.stringValue ?? "1.0",
            tls13: t?.value.boolValue ?? false,
            opportunisticEncryption: oe?.value.boolValue ?? false,
            opportunisticOnion: oo?.value.boolValue ?? false,
            hsts: hstsSettings
        )
    }

    func updateSSLMode(zoneId: String, mode: String) async throws {
        _ = try await ZoneService.shared.updateZoneSetting(zoneId: zoneId, settingName: "ssl", value: mode)
    }

    func updateAlwaysUseHTTPS(zoneId: String, isOn: Bool) async throws {
        _ = try await ZoneService.shared.updateZoneSetting(zoneId: zoneId, settingName: "always_use_https", value: isOn ? "on" : "off")
    }

    func updateAutomaticHTTPSRewrites(zoneId: String, isOn: Bool) async throws {
        _ = try await ZoneService.shared.updateZoneSetting(zoneId: zoneId, settingName: "automatic_https_rewrites", value: isOn ? "on" : "off")
    }

    func updateMinTLSVersion(zoneId: String, version: String) async throws {
        _ = try await ZoneService.shared.updateZoneSetting(zoneId: zoneId, settingName: "min_tls_version", value: version)
    }

    func updateTLS13(zoneId: String, isOn: Bool) async throws {
        _ = try await ZoneService.shared.updateZoneSetting(zoneId: zoneId, settingName: "tls_1_3", value: isOn ? "on" : "off")
    }

    func updateOpportunisticEncryption(zoneId: String, isOn: Bool) async throws {
        _ = try await ZoneService.shared.updateZoneSetting(zoneId: zoneId, settingName: "opportunistic_encryption", value: isOn ? "on" : "off")
    }

    func updateOpportunisticOnion(zoneId: String, isOn: Bool) async throws {
        _ = try await ZoneService.shared.updateZoneSetting(zoneId: zoneId, settingName: "opportunistic_onion", value: isOn ? "on" : "off")
    }

    func updateHSTS(zoneId: String, enabled: Bool, maxAge: Int, subdomains: Bool, nosniff: Bool, preload: Bool) async throws {
        let payload: [String: Any] = [
            "value": [
                "strict_transport_security": [
                    "enabled": enabled,
                    "max_age": maxAge,
                    "include_subdomains": subdomains,
                    "nosniff": nosniff,
                    "preload": preload
                ]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/settings/security_header", method: "PATCH", body: data)
        let (setting, _): (ZoneSetting?, ResultInfo?) = try await client.performRequest(request)
        guard setting != nil else {
            throw APIError.cloudflareError("Failed to update HSTS settings.")
        }
    }
}
