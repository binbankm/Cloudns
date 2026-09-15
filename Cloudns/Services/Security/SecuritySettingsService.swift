import Foundation

/// Protocol defining Cloudflare domain security levels and Bot Fight mode service
protocol SecuritySettingsServiceProtocol: Sendable {
    func fetchZoneSettings(zoneId: String) async throws -> [ZoneSetting]
    func getSecuritySettings(zoneId: String) async throws -> SecuritySettings
    func getBotManagement(zoneId: String) async throws -> BotManagementConfig?
    func updateSecurityLevel(zoneId: String, level: String) async throws
    func updateChallengeTTL(zoneId: String, ttl: Int) async throws
    func updateBrowserCheck(zoneId: String, isOn: Bool) async throws
    func updateBotFightMode(zoneId: String, isOn: Bool) async throws
    func setUnderAttackMode(zoneId: String, enabled: Bool) async throws
}

/// Concrete domain service for Cloudflare core security levels and bot protection
final class SecuritySettingsService: SecuritySettingsServiceProtocol {
    static let shared = SecuritySettingsService()

    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared

    private init() {}

    // MARK: - General Security Settings

    func fetchZoneSettings(zoneId: String) async throws -> [ZoneSetting] {
        try await ZoneService.shared.getZoneSettings(zoneId: zoneId)
    }

    func getBotManagement(zoneId: String) async throws -> BotManagementConfig? {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/bot_management")
        let (config, _): (BotManagementConfig?, ResultInfo?) = try await client.performRequest(request)
        return config
    }

    func getSecuritySettings(zoneId: String) async throws -> SecuritySettings {
        let allSettings = await (try? fetchZoneSettings(zoneId: zoneId)) ?? []

        var secLevel: ZoneSetting?
        var ttl: ZoneSetting?
        var browser: ZoneSetting?

        if !allSettings.isEmpty {
            secLevel = allSettings.first(where: { $0.id == "security_level" })
            ttl = allSettings.first(where: { $0.id == "challenge_ttl" })
            browser = allSettings.first(where: { $0.id == "browser_check" })
        } else {
            async let sec = try? getSetting(zoneId: zoneId, settingName: "security_level")
            async let t = try? getSetting(zoneId: zoneId, settingName: "challenge_ttl")
            async let b = try? getSetting(zoneId: zoneId, settingName: "browser_check")
            let (resSec, resT, resB) = await (sec, t, b)
            secLevel = resSec
            ttl = resT
            browser = resB
        }

        let botConfig = try? await getBotManagement(zoneId: zoneId)
        let botFightMode = botConfig?.fight_mode ?? false

        return SecuritySettings(
            securityLevel: secLevel?.value.stringValue ?? "medium",
            challengeTTL: ttl?.value.intValue ?? 1800,
            browserCheck: browser?.value.boolValue ?? true,
            botFightMode: botFightMode,
            botManagement: botConfig
        )
    }

    func updateSecurityLevel(zoneId: String, level: String) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "security_level", value: level)
    }

    func updateChallengeTTL(zoneId: String, ttl: Int) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "challenge_ttl", value: ttl)
    }

    func updateBrowserCheck(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "browser_check", value: isOn ? "on" : "off")
    }

    func updateBotFightMode(zoneId: String, isOn: Bool) async throws {
        let payload: [String: Any] = ["fight_mode": isOn]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/bot_management", method: "PUT", body: data)
        let (_, _): (BotManagementConfig?, ResultInfo?) = try await client.performRequest(request)
    }

    func setUnderAttackMode(zoneId: String, enabled: Bool) async throws {
        try await updateSecurityLevel(zoneId: zoneId, level: enabled ? "under_attack" : "medium")
    }

    // MARK: - Centralized Zone Setting Delegation

    private func getSetting(zoneId: String, settingName: String) async throws -> ZoneSetting? {
        try await ZoneService.shared.getZoneSetting(zoneId: zoneId, settingName: settingName)
    }

    private func updateSetting(zoneId: String, settingName: String, value: Any) async throws -> ZoneSetting {
        try await ZoneService.shared.updateZoneSetting(zoneId: zoneId, settingName: settingName, value: value)
    }
}
