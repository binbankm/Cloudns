import Foundation

/// Protocol defining Cloudflare Scrape Shield privacy protection service
protocol ScrapeShieldServiceProtocol: Sendable {
    func getScrapeShieldSettings(zoneId: String) async throws -> ScrapeShieldSettings
    func updateEmailObfuscation(zoneId: String, isOn: Bool) async throws
    func updateServerSideExcludes(zoneId: String, isOn: Bool) async throws
    func updateHotlinkProtection(zoneId: String, isOn: Bool) async throws
    func updateScrapeShieldSetting(zoneId: String, settingId: String, value: String) async throws
}

/// Concrete domain service for Cloudflare Scrape Shield
final class ScrapeShieldService: ScrapeShieldServiceProtocol {
    static let shared = ScrapeShieldService()

    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared

    private init() {}

    func getScrapeShieldSettings(zoneId: String) async throws -> ScrapeShieldSettings {
        async let e = try? getSetting(zoneId: zoneId, settingName: "email_obfuscation")
        async let s = try? getSetting(zoneId: zoneId, settingName: "server_side_exclude")
        async let h = try? getSetting(zoneId: zoneId, settingName: "hotlink_protection")
        let (email, sse, hotlink) = await (e, s, h)

        return ScrapeShieldSettings(
            emailObfuscation: (email?.value.stringValue ?? "off") == "on",
            serverSideExcludes: (sse?.value.stringValue ?? "off") == "on",
            hotlinkProtection: (hotlink?.value.stringValue ?? "off") == "on"
        )
    }

    func updateEmailObfuscation(zoneId: String, isOn: Bool) async throws {
        try await updateScrapeShieldSetting(zoneId: zoneId, settingId: "email_obfuscation", value: isOn ? "on" : "off")
    }

    func updateServerSideExcludes(zoneId: String, isOn: Bool) async throws {
        try await updateScrapeShieldSetting(zoneId: zoneId, settingId: "server_side_exclude", value: isOn ? "on" : "off")
    }

    func updateHotlinkProtection(zoneId: String, isOn: Bool) async throws {
        try await updateScrapeShieldSetting(zoneId: zoneId, settingId: "hotlink_protection", value: isOn ? "on" : "off")
    }

    func updateScrapeShieldSetting(zoneId: String, settingId: String, value: String) async throws {
        _ = try await ZoneService.shared.updateZoneSetting(zoneId: zoneId, settingName: settingId, value: value)
    }

    private func getSetting(zoneId: String, settingName: String) async throws -> ZoneSetting? {
        try await ZoneService.shared.getZoneSetting(zoneId: zoneId, settingName: settingName)
    }
}
