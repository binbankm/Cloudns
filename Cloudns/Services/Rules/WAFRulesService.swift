import Foundation

/// Cloudflare WAF 规则集、Transform Rules 与 Cache Rules 领域服务抽象协议
protocol WAFRulesServiceProtocol: Sendable {
    func fetchRulesetByPhase(zoneId: String, phase: String) async throws -> Ruleset?
    func updateRulesetRules(zoneId: String, phase: String, rules: [WAFRule]) async throws -> Ruleset
    func updateWAFRule(zoneId: String, rulesetId: String, ruleId: String, action: String, expression: String, description: String?, enabled: Bool, ratelimit: RateLimitConfig?, actionParameters: ActionParameters?) async throws
    func deleteWAFRule(zoneId: String, rulesetId: String, ruleId: String) async throws
    func createWAFRule(zoneId: String, rulesetId: String, action: String, expression: String, description: String?, enabled: Bool, ratelimit: RateLimitConfig?, actionParameters: ActionParameters?) async throws -> Ruleset
    func createRuleset(zoneId: String, phase: String, action: String, expression: String, description: String?, enabled: Bool, ratelimit: RateLimitConfig?, actionParameters: ActionParameters?) async throws -> Ruleset
}

extension WAFRulesServiceProtocol {
    func updateWAFRule(
        zoneId: String,
        rulesetId: String,
        ruleId: String,
        action: String,
        expression: String,
        description: String?,
        enabled: Bool,
        ratelimit: RateLimitConfig? = nil,
        actionParameters: ActionParameters? = nil
    ) async throws {
        try await updateWAFRule(zoneId: zoneId, rulesetId: rulesetId, ruleId: ruleId, action: action, expression: expression, description: description, enabled: enabled, ratelimit: ratelimit, actionParameters: actionParameters)
    }
    
    func createWAFRule(
        zoneId: String,
        rulesetId: String,
        action: String,
        expression: String,
        description: String?,
        enabled: Bool,
        ratelimit: RateLimitConfig? = nil,
        actionParameters: ActionParameters? = nil
    ) async throws -> Ruleset {
        try await createWAFRule(zoneId: zoneId, rulesetId: rulesetId, action: action, expression: expression, description: description, enabled: enabled, ratelimit: ratelimit, actionParameters: actionParameters)
    }
    
    func createRuleset(
        zoneId: String,
        phase: String,
        action: String,
        expression: String,
        description: String?,
        enabled: Bool,
        ratelimit: RateLimitConfig? = nil,
        actionParameters: ActionParameters? = nil
    ) async throws -> Ruleset {
        try await createRuleset(zoneId: zoneId, phase: phase, action: action, expression: expression, description: description, enabled: enabled, ratelimit: ratelimit, actionParameters: actionParameters)
    }
}

/// 统一的 Cloudflare WAF 规则集、Transform Rules 与 Cache Rules 领域服务
final class WAFRulesService: WAFRulesServiceProtocol {
    static let shared = WAFRulesService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func fetchRulesetByPhase(zoneId: String, phase: String) async throws -> Ruleset? {
        do {
            let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/rulesets/phases/\(phase)/entrypoint")
            let (ruleset, _): (Ruleset?, ResultInfo?) = try await client.performRequest(request)
            return ruleset
        } catch {
            return nil
        }
    }
    
    func updateRulesetRules(zoneId: String, phase: String, rules: [WAFRule]) async throws -> Ruleset {
        let encoder = JSONEncoder()
        let rulesData = try encoder.encode(rules)
        let rulesArray = try JSONSerialization.jsonObject(with: rulesData)
        let payload: [String: Any] = ["rules": rulesArray]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(
            path: "zones/\(zoneId)/rulesets/phases/\(phase)/entrypoint",
            method: "PUT",
            body: data
        )
        let (ruleset, _): (Ruleset?, ResultInfo?) = try await client.performRequest(request)
        guard let rs = ruleset else { throw APIError.cloudflareError("Failed to update ruleset.") }
        return rs
    }
    
    func updateWAFRule(
        zoneId: String,
        rulesetId: String,
        ruleId: String,
        action: String,
        expression: String,
        description: String?,
        enabled: Bool,
        ratelimit: RateLimitConfig?,
        actionParameters: ActionParameters?
    ) async throws {
        var payload: [String: Any] = [
            "action": action,
            "expression": expression,
            "enabled": enabled
        ]
        if let desc = description { payload["description"] = desc }
        if let ap = actionParameters {
            let data = try JSONEncoder().encode(ap)
            payload["action_parameters"] = try JSONSerialization.jsonObject(with: data)
        }
        if let rl = ratelimit {
            let data = try JSONEncoder().encode(rl)
            payload["ratelimit"] = try JSONSerialization.jsonObject(with: data)
        }
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(
            path: "zones/\(zoneId)/rulesets/\(rulesetId)/rules/\(ruleId)",
            method: "PATCH",
            body: data
        )
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func deleteWAFRule(zoneId: String, rulesetId: String, ruleId: String) async throws {
        let request = try factory.createAuthenticatedRequest(
            path: "zones/\(zoneId)/rulesets/\(rulesetId)/rules/\(ruleId)",
            method: "DELETE"
        )
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func createWAFRule(
        zoneId: String,
        rulesetId: String,
        action: String,
        expression: String,
        description: String?,
        enabled: Bool,
        ratelimit: RateLimitConfig?,
        actionParameters: ActionParameters?
    ) async throws -> Ruleset {
        var payload: [String: Any] = [
            "action": action,
            "expression": expression,
            "enabled": enabled
        ]
        if let desc = description { payload["description"] = desc }
        if let ap = actionParameters {
            let data = try JSONEncoder().encode(ap)
            payload["action_parameters"] = try JSONSerialization.jsonObject(with: data)
        }
        if let rl = ratelimit {
            let data = try JSONEncoder().encode(rl)
            payload["ratelimit"] = try JSONSerialization.jsonObject(with: data)
        }
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(
            path: "zones/\(zoneId)/rulesets/\(rulesetId)/rules",
            method: "POST",
            body: data
        )
        let (ruleset, _): (Ruleset?, ResultInfo?) = try await client.performRequest(request)
        guard let rs = ruleset else { throw APIError.cloudflareError("Failed to create rule.") }
        return rs
    }
    
    func createRuleset(
        zoneId: String,
        phase: String,
        action: String,
        expression: String,
        description: String?,
        enabled: Bool,
        ratelimit: RateLimitConfig?,
        actionParameters: ActionParameters?
    ) async throws -> Ruleset {
        var rulePayload: [String: Any] = [
            "action": action,
            "expression": expression,
            "enabled": enabled
        ]
        if let desc = description { rulePayload["description"] = desc }
        if let ap = actionParameters {
            let data = try JSONEncoder().encode(ap)
            rulePayload["action_parameters"] = try JSONSerialization.jsonObject(with: data)
        }
        if let rl = ratelimit {
            let data = try JSONEncoder().encode(rl)
            rulePayload["ratelimit"] = try JSONSerialization.jsonObject(with: data)
        }
        let payload: [String: Any] = [
            "description": "\(phase) ruleset",
            "rules": [rulePayload]
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(
            path: "zones/\(zoneId)/rulesets/phases/\(phase)/entrypoint",
            method: "PUT",
            body: data
        )
        let (ruleset, _): (Ruleset?, ResultInfo?) = try await client.performRequest(request)
        guard let rs = ruleset else { throw APIError.cloudflareError("Failed to create ruleset.") }
        return rs
    }
}
