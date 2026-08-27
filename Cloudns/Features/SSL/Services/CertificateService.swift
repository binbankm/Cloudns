import Foundation

/// Cloudflare SSL / TLS 与边缘证书管理领域服务抽象协议
protocol CertificateServiceProtocol: Sendable {
    func getSSLSettings(zoneId: String) async throws -> (
        sslMode: String,
        alwaysUseHTTPS: Bool,
        automaticHTTPSRewrites: Bool,
        minTLSVersion: String,
        tls13: Bool,
        opportunisticEncryption: Bool,
        opportunisticOnion: Bool,
        hsts: (enabled: Bool, maxAge: Int, subdomains: Bool, nosniff: Bool, preload: Bool)
    )
    func updateSSLMode(zoneId: String, mode: String) async throws
    func updateAlwaysUseHTTPS(zoneId: String, isOn: Bool) async throws
    func updateAutomaticHTTPSRewrites(zoneId: String, isOn: Bool) async throws
    func updateMinTLSVersion(zoneId: String, version: String) async throws
    func updateTLS13(zoneId: String, isOn: Bool) async throws
    func updateOpportunisticEncryption(zoneId: String, isOn: Bool) async throws
    func updateOpportunisticOnion(zoneId: String, isOn: Bool) async throws
    func updateHSTS(zoneId: String, enabled: Bool, maxAge: Int, subdomains: Bool, nosniff: Bool, preload: Bool) async throws
    func getCertificates(zoneId: String) async throws -> [CertificatePack]
    func getUniversalSSLSetting(zoneId: String) async throws -> Bool
    func updateUniversalSSL(zoneId: String, enabled: Bool) async throws
    func deleteCertificatePack(zoneId: String, packId: String) async throws
    func fetchCustomCertificates(zoneId: String) async throws -> [CustomCertificate]
    func deleteCustomCertificate(zoneId: String, certificateId: String) async throws
}

/// 统一的 Cloudflare SSL / TLS 与边缘证书管理领域服务
final class CertificateService: CertificateServiceProtocol {
    // MARK: - Lifecycle & Dependencies
     = CertificateService()
    
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
        hsts: (enabled: Bool, maxAge: Int, subdomains: Bool, nosniff: Bool, preload: Bool)
    ) {
        let allSettings = (try? await fetchZoneSettings(zoneId: zoneId)) ?? []
        
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
            async let ssl = try? getSetting(zoneId: zoneId, settingName: "ssl")
            async let https = try? getSetting(zoneId: zoneId, settingName: "always_use_https")
            async let rewrites = try? getSetting(zoneId: zoneId, settingName: "automatic_https_rewrites")
            async let minTLS = try? getSetting(zoneId: zoneId, settingName: "min_tls_version")
            async let tls13 = try? getSetting(zoneId: zoneId, settingName: "tls_1_3")
            async let oppEnc = try? getSetting(zoneId: zoneId, settingName: "opportunistic_encryption")
            async let oppOnion = try? getSetting(zoneId: zoneId, settingName: "opportunistic_onion")
            async let hsts = try? getSetting(zoneId: zoneId, settingName: "security_header")
            
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
        var hstsMaxAge = 2592000
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
        
        return (
            sslMode: s?.value.stringValue ?? "off",
            alwaysUseHTTPS: h?.value.boolValue ?? false,
            automaticHTTPSRewrites: r?.value.boolValue ?? false,
            minTLSVersion: mt?.value.stringValue ?? "1.0",
            tls13: t?.value.boolValue ?? false,
            opportunisticEncryption: oe?.value.boolValue ?? false,
            opportunisticOnion: oo?.value.boolValue ?? false,
            hsts: (enabled: hstsEnabled, maxAge: hstsMaxAge, subdomains: hstsSubdomains, nosniff: hstsNoSniff, preload: hstsPreload)
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
        guard let enabled = setting?.enabled else {
            throw APIError.decodingError("Universal SSL settings unavailable in response")
        }
        return enabled
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
    
    func deleteCertificatePack(zoneId: String, packId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/ssl/certificate_packs/\(packId)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func fetchCustomCertificates(zoneId: String) async throws -> [CustomCertificate] {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/custom_certificates")
        let (certs, _): ([CustomCertificate]?, ResultInfo?) = try await client.performRequest(request)
        return certs ?? []
    }
    
    func deleteCustomCertificate(zoneId: String, certificateId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/custom_certificates/\(certificateId)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
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
