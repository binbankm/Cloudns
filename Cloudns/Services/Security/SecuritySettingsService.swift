import Foundation

/// Protocol defining Cloudflare domain security and defense service
protocol SecuritySettingsServiceProtocol: Sendable {
    func fetchZoneSettings(zoneId: String) async throws -> [ZoneSetting]
    func getSecuritySettings(zoneId: String) async throws -> (level: String, challengeTTL: Int, browserCheck: Bool, botFightMode: Bool)
    func updateSecuritySetting(zoneId: String, settingName: String, value: Any) async throws -> ZoneSetting
    func updateSecurityLevel(zoneId: String, level: String) async throws
    func updateChallengeTTL(zoneId: String, ttl: Int) async throws
    func updateBrowserCheck(zoneId: String, isOn: Bool) async throws
    func updateBotFightMode(zoneId: String, isOn: Bool) async throws
    func getWAFRules(zoneId: String) async throws -> [WAFRule]
    func updateWAFRules(zoneId: String, rules: [WAFRule]) async throws -> [WAFRule]
    func getIPAccessRules(zoneId: String, page: Int, perPage: Int) async throws -> ([IPAccessRule], ResultInfo?)
    func createIPAccessRule(zoneId: String, mode: String, target: String, value: String, notes: String?) async throws -> IPAccessRule
    func deleteIPAccessRule(zoneId: String, ruleId: String) async throws
    func fetchSecurityEvents(zoneId: String, limit: Int) async throws -> [SecurityEvent]
    func getScrapeShieldSettings(zoneId: String) async throws -> (emailObfuscation: String, serverSideExcludes: String, hotlinkProtection: String)
    func updateScrapeShieldSetting(zoneId: String, settingId: String, value: String) async throws
}

/// Concrete domain service for Cloudflare domain security
final class SecuritySettingsService: SecuritySettingsServiceProtocol {
    static let shared = SecuritySettingsService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    private let wafRulesService = WAFRulesService.shared
    
    private init() {}
    
    // MARK: - General Security Settings
    
    func fetchZoneSettings(zoneId: String) async throws -> [ZoneSetting] {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/settings")
        let (settings, _): ([ZoneSetting]?, ResultInfo?) = try await client.performRequest(request)
        return settings ?? []
    }
    
    func getBotManagement(zoneId: String) async throws -> BotManagementConfig? {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/bot_management")
        let (config, _): (BotManagementConfig?, ResultInfo?) = try await client.performRequest(request)
        return config
    }

    func getSecuritySettings(zoneId: String) async throws -> (level: String, challengeTTL: Int, browserCheck: Bool, botFightMode: Bool) {
        let allSettings = (try? await fetchZoneSettings(zoneId: zoneId)) ?? []
        
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
        
        return (
            level: secLevel?.value.stringValue ?? "medium",
            challengeTTL: ttl?.value.intValue ?? 1800,
            browserCheck: browser?.value.boolValue ?? true,
            botFightMode: botFightMode
        )
    }
    
    func updateSecuritySetting(zoneId: String, settingName: String, value: Any) async throws -> ZoneSetting {
        try await updateSetting(zoneId: zoneId, settingName: settingName, value: value)
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
    
    // MARK: - Scrape Shield
    
    func getScrapeShieldSettings(zoneId: String) async throws -> (emailObfuscation: String, serverSideExcludes: String, hotlinkProtection: String) {
        let allSettings = (try? await fetchZoneSettings(zoneId: zoneId)) ?? []
        
        var email: ZoneSetting?
        var sse: ZoneSetting?
        var hotlink: ZoneSetting?
        
        if !allSettings.isEmpty {
            email = allSettings.first(where: { $0.id == "email_obfuscation" })
            sse = allSettings.first(where: { $0.id == "server_side_exclude" })
            hotlink = allSettings.first(where: { $0.id == "hotlink_protection" })
        } else {
            async let e = try? getSetting(zoneId: zoneId, settingName: "email_obfuscation")
            async let s = try? getSetting(zoneId: zoneId, settingName: "server_side_exclude")
            async let h = try? getSetting(zoneId: zoneId, settingName: "hotlink_protection")
            let (resE, resS, resH) = await (e, s, h)
            email = resE
            sse = resS
            hotlink = resH
        }
        
        return (
            emailObfuscation: email?.value.stringValue ?? "off",
            serverSideExcludes: sse?.value.stringValue ?? "off",
            hotlinkProtection: hotlink?.value.stringValue ?? "off"
        )
    }
    
    func updateScrapeShieldSetting(zoneId: String, settingId: String, value: String) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: settingId, value: value)
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
    
    // MARK: - WAF Rulesets
    
    func getWAFRules(zoneId: String) async throws -> [WAFRule] {
        let rs = try? await wafRulesService.fetchRulesetByPhase(zoneId: zoneId, phase: "http_request_firewall_custom")
        return rs?.rules ?? []
    }
    
    func updateWAFRules(zoneId: String, rules: [WAFRule]) async throws -> [WAFRule] {
        let encoder = JSONEncoder()
        let rulesData = try encoder.encode(rules)
        let rulesArray = try JSONSerialization.jsonObject(with: rulesData)
        let payload: [String: Any] = ["rules": rulesArray]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(
            path: "zones/\(zoneId)/rulesets/phases/http_request_firewall_custom/entrypoint",
            method: "PUT",
            body: data
        )
        let (ruleset, _): (Ruleset?, ResultInfo?) = try await client.performRequest(request)
        return ruleset?.rules ?? []
    }
    
    // MARK: - IP Access Rules
    
    func getIPAccessRules(zoneId: String, page: Int = 1, perPage: Int = 50) async throws -> ([IPAccessRule], ResultInfo?) {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/firewall/access_rules/rules", queryItems: queryItems)
        let (rules, info): ([IPAccessRule]?, ResultInfo?) = try await client.performRequest(request)
        return (rules ?? [], info)
    }
    
    func createIPAccessRule(zoneId: String, mode: String, target: String, value: String, notes: String?) async throws -> IPAccessRule {
        let config: [String: String] = [
            "target": target,
            "value": value
        ]
        var payload: [String: Any] = [
            "mode": mode,
            "configuration": config
        ]
        if let n = notes, !n.isEmpty {
            payload["notes"] = n
        }
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/firewall/access_rules/rules", method: "POST", body: data)
        let (rule, _): (IPAccessRule?, ResultInfo?) = try await client.performRequest(request)
        guard let r = rule else { throw APIError.cloudflareError("Failed to create IP rule") }
        return r
    }
    
    func deleteIPAccessRule(zoneId: String, ruleId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/firewall/access_rules/rules/\(ruleId)", method: "DELETE")
        struct DeleteRes: Codable { let id: String? }
        let (_, _): (DeleteRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    // MARK: - Security Events (GraphQL firewallEventsAdaptive)
    
    func fetchSecurityEvents(zoneId: String, limit: Int = 30) async throws -> [SecurityEvent] {
        let date = Calendar.current.date(byAdding: .hour, value: -23, to: Date()) ?? Date()
        let dateString = DateFormatters.iso8601.string(from: date)
        
        let query = """
        query {
            viewer {
                zones(filter: { zoneTag: "\(zoneId)" }) {
                    firewallEventsAdaptive(filter: { datetime_gt: "\(dateString)" }, limit: \(limit), orderBy: [datetime_DESC]) {
                        action
                        clientIP
                        clientCountryName
                        clientAsn
                        datetime
                        source
                        edgeResponseStatus
                        clientRequestHTTPHost
                        ruleId
                    }
                }
            }
        }
        """
        let payload: [String: Any] = ["query": query]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "graphql", method: "POST", body: data)
        let rawData = try await client.performDataRequest(request)
        
        do {
            let decoded = try JSONDecoder().decode(GraphQLResponse<SecurityGraphQLData>.self, from: rawData)
            if let errors = decoded.errors, !errors.isEmpty, decoded.data == nil {
                throw APIError.cloudflareError(errors.first?.message ?? "Failed to fetch security events")
            }
            return decoded.data?.viewer.zones.first?.firewallEventsAdaptive ?? []
        } catch let apiError as APIError {
            throw apiError
        } catch {
            return []
        }
    }
}
