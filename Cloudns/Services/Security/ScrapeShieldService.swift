import Foundation

/// Cloudflare Scrape Shield 防爬虫与隐私保护领域服务协议
protocol ScrapeShieldServiceProtocol: Sendable {
    func getScrapeShieldSettings(zoneId: String) async throws -> (emailObfuscation: String, serverSideExcludes: String, hotlinkProtection: String)
    func updateScrapeShieldSetting(zoneId: String, settingId: String, value: String) async throws
}

/// 统一的 Cloudflare Scrape Shield 领域服务
final class ScrapeShieldService: ScrapeShieldServiceProtocol {
    static let shared = ScrapeShieldService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func getScrapeShieldSettings(zoneId: String) async throws -> (emailObfuscation: String, serverSideExcludes: String, hotlinkProtection: String) {
        async let e = try? getSetting(zoneId: zoneId, settingName: "email_obfuscation")
        async let s = try? getSetting(zoneId: zoneId, settingName: "server_side_exclude")
        async let h = try? getSetting(zoneId: zoneId, settingName: "hotlink_protection")
        let (email, sse, hotlink) = await (e, s, h)
        
        return (
            emailObfuscation: email?.value.stringValue ?? "off",
            serverSideExcludes: sse?.value.stringValue ?? "off",
            hotlinkProtection: hotlink?.value.stringValue ?? "off"
        )
    }
    
    func updateScrapeShieldSetting(zoneId: String, settingId: String, value: String) async throws {
        let payload = ["value": value]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/settings/\(settingId)", method: "PATCH", body: data)
        let (_, _): (ZoneSetting?, ResultInfo?) = try await client.performRequest(request)
    }
    
    private func getSetting(zoneId: String, settingName: String) async throws -> ZoneSetting? {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/settings/\(settingName)")
        let (setting, _): (ZoneSetting?, ResultInfo?) = try await client.performRequest(request)
        return setting
    }
}
