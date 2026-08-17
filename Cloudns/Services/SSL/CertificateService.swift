import Foundation

/// 统一的 Cloudflare SSL / TLS 与边缘证书管理领域服务
final class CertificateService {
    static let shared = CertificateService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    // MARK: - SSL Settings
    
    func getSSLSettings(zoneId: String) async throws -> (
        sslMode: String,
        alwaysUseHTTPS: Bool,
        automaticHTTPSRewrites: Bool,
        minTLSVersion: String,
        tls13: Bool,
        opportunisticEncryption: Bool,
        opportunisticOnion: Bool,
        hsts: (enabled: Bool, maxAge: Int, subdomains: Bool, nosniff: Bool)
    ) {
        async let ssl = getSetting(zoneId: zoneId, settingName: "ssl")
        async let https = getSetting(zoneId: zoneId, settingName: "always_use_https")
        async let rewrites = getSetting(zoneId: zoneId, settingName: "automatic_https_rewrites")
        async let minTLS = getSetting(zoneId: zoneId, settingName: "min_tls_version")
        async let tls13 = getSetting(zoneId: zoneId, settingName: "tls_1_3")
        async let oppEnc = getSetting(zoneId: zoneId, settingName: "opportunistic_encryption")
        async let oppOnion = getSetting(zoneId: zoneId, settingName: "opportunistic_onion")
        async let hsts = getSetting(zoneId: zoneId, settingName: "security_header")
        
        let (s, h, r, mt, t, oe, oo, sh) = try await (ssl, https, rewrites, minTLS, tls13, oppEnc, oppOnion, hsts)
        
        var hstsEnabled = false
        var hstsMaxAge = 2592000
        var hstsSubdomains = false
        var hstsNoSniff = false
        
        if let headerDict = sh?.value as? [String: Any],
           let strictHeader = headerDict["strict_transport_security"] as? [String: Any] {
            hstsEnabled = (strictHeader["enabled"] as? Bool) ?? false
            hstsMaxAge = (strictHeader["max_age"] as? Int) ?? 2592000
            hstsSubdomains = (strictHeader["include_subdomains"] as? Bool) ?? false
            hstsNoSniff = (strictHeader["nosniff"] as? Bool) ?? false
        }
        
        return (
            sslMode: (s?.value as? String) ?? "off",
            alwaysUseHTTPS: ((h?.value as? String) ?? "off") == "on",
            automaticHTTPSRewrites: ((r?.value as? String) ?? "off") == "on",
            minTLSVersion: (mt?.value as? String) ?? "1.0",
            tls13: ((t?.value as? String) ?? "off") == "on",
            opportunisticEncryption: ((oe?.value as? String) ?? "off") == "on",
            opportunisticOnion: ((oo?.value as? String) ?? "off") == "on",
            hsts: (hstsEnabled, hstsMaxAge, hstsSubdomains, hstsNoSniff)
        )
    }
    
    func updateSSLMode(zoneId: String, mode: String) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "ssl", value: mode)
    }
    
    func updateAlwaysUseHTTPS(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "always_use_https", value: isOn ? "on" : "off")
    }
    
    func updateAutomaticHTTPSRewrites(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "automatic_https_rewrites", value: isOn ? "on" : "off")
    }
    
    func updateMinTLSVersion(zoneId: String, version: String) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "min_tls_version", value: version)
    }
    
    func updateTLS13(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "tls_1_3", value: isOn ? "on" : "off")
    }
    
    func updateOpportunisticEncryption(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "opportunistic_encryption", value: isOn ? "on" : "off")
    }
    
    func updateOpportunisticOnion(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "opportunistic_onion", value: isOn ? "on" : "off")
    }
    
    func updateHSTS(zoneId: String, enabled: Bool, maxAge: Int, subdomains: Bool, nosniff: Bool) async throws {
        let payload: [String: Any] = [
            "value": [
                "strict_transport_security": [
                    "enabled": enabled,
                    "max_age": maxAge,
                    "include_subdomains": subdomains,
                    "nosniff": nosniff
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
    
    // MARK: - Edge Certificates
    
    func getCertificates(zoneId: String) async throws -> [CertificatePack] {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/ssl/certificate_packs")
        let (certs, _): ([CertificatePack]?, ResultInfo?) = try await client.performRequest(request)
        return certs ?? []
    }
    
    func getUniversalSSLSetting(zoneId: String) async throws -> Bool {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/ssl/universal/settings")
        struct UniversalSSLSettingResult: Codable {
            let enabled: Bool?
        }
        let (setting, _): (UniversalSSLSettingResult?, ResultInfo?) = try await client.performRequest(request)
        return setting?.enabled ?? true
    }
    
    func updateUniversalSSL(zoneId: String, enabled: Bool) async throws {
        let payload = ["enabled": enabled]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/ssl/universal/settings", method: "PATCH", body: data)
        struct UniversalSSLSettingResult: Codable {
            let enabled: Bool?
        }
        let (_, _): (UniversalSSLSettingResult?, ResultInfo?) = try await client.performRequest(request)
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
