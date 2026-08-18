import Foundation

struct RulesetsResponse: Codable, Sendable {
    let success: Bool
    let errors: [CloudflareError]?
    let result: [Ruleset]?
}

struct SingleRulesetResponse: Codable, Sendable {
    let success: Bool
    let errors: [CloudflareError]?
    let result: Ruleset?
}

struct Ruleset: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let description: String?
    let kind: String?
    let phase: String
    let rules: [WAFRule]?
}

struct WAFRule: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let action: String
    let expression: String
    let description: String?
    let enabled: Bool
    let ratelimit: RateLimitConfig?
    let action_parameters: ActionParameters?
    
    init(
        id: String,
        action: String = "block",
        expression: String = "(http.request.uri.path contains \"/wp-admin\")",
        description: String? = "Block Admin Endpoint Access",
        enabled: Bool = true,
        ratelimit: RateLimitConfig? = nil,
        action_parameters: ActionParameters? = nil
    ) {
        self.id = id
        self.action = action
        self.expression = expression
        self.description = description
        self.enabled = enabled
        self.ratelimit = ratelimit
        self.action_parameters = action_parameters
    }
    
    static let placeholders: [WAFRule] = [
        WAFRule(id: "rule_1", action: "block", expression: "(http.request.uri.path contains \"/admin\")", description: "Block unauthorized admin login attempts"),
        WAFRule(id: "rule_2", action: "managed_challenge", expression: "(ip.geoip.country eq \"T1\")", description: "Challenge Tor Exit Nodes"),
        WAFRule(id: "rule_3", action: "js_challenge", expression: "(cf.threat_score gt 30)", description: "JS Challenge High Threat Score")
    ]
}

struct RateLimitConfig: Codable, Equatable, Sendable {
    let characteristics: [String]?
    let mitigation_timeout: Int?
    let period: Int
    let requests_per_period: Int
}

struct UpdateWAFRuleRequest: Codable, Sendable {
    let action: String
    let expression: String
    let description: String?
    let enabled: Bool
    let ratelimit: RateLimitConfig?
    let action_parameters: ActionParameters?
}

struct UpdateWAFRuleResponse: Codable, Sendable {
    let success: Bool
    let errors: [CloudflareError]?
    let result: Ruleset? // The API returns the whole ruleset when updating a rule
}

struct WAFEntrypointUpdate: Codable, Sendable {
    let rules: [UpdateWAFRuleRequest]
}
