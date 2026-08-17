import Foundation

/// 统一的 Cloudflare 域名安全与防御领域服务
final class SecuritySettingsService {
    static let shared = SecuritySettingsService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    // MARK: - General Security Settings
    
    func fetchZoneSettings(zoneId: String) async throws -> [ZoneSetting] {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/settings")
        let (settings, _): ([ZoneSetting]?, ResultInfo?) = try await client.performRequest(request)
        return settings ?? []
    }
    
    func getSecuritySettings(zoneId: String) async throws -> (level: String, challengeTTL: Int, browserCheck: Bool, botFightMode: Bool) {
        async let secLevel = getSetting(zoneId: zoneId, settingName: "security_level")
        async let ttl = getSetting(zoneId: zoneId, settingName: "challenge_ttl")
        async let browser = getSetting(zoneId: zoneId, settingName: "browser_check")
        async let bot = getSetting(zoneId: zoneId, settingName: "bot_fight_mode")
        
        let (l, t, b, bf) = try await (secLevel, ttl, browser, bot)
        return (
            level: (l?.value as? String) ?? "medium",
            challengeTTL: (t?.value as? Int) ?? 1800,
            browserCheck: ((b?.value as? String) ?? "on") == "on",
            botFightMode: ((bf?.value as? String) ?? "off") == "on"
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
        _ = try await updateSetting(zoneId: zoneId, settingName: "bot_fight_mode", value: isOn ? "on" : "off")
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
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/rulesets/phases/http_request_firewall_custom/entrypoint")
        let (ruleset, _): (Ruleset?, ResultInfo?) = try await client.performRequest(request)
        return ruleset?.rules ?? []
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
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: date)
        
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
