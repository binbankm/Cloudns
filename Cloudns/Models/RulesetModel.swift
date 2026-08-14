import Foundation

struct RulesetsResponse: Codable {
    let success: Bool
    let errors: [CloudflareError]?
    let result: [Ruleset]?
}

struct SingleRulesetResponse: Codable {
    let success: Bool
    let errors: [CloudflareError]?
    let result: Ruleset?
}

struct Ruleset: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let kind: String?
    let phase: String
    let rules: [WAFRule]?
}

struct WAFRule: Codable, Identifiable {
    let id: String
    let action: String
    let expression: String
    let description: String?
    let enabled: Bool
    let ratelimit: RateLimitConfig?
    let action_parameters: ActionParameters?
}

struct RateLimitConfig: Codable {
    let characteristics: [String]?
    let mitigation_timeout: Int?
    let period: Int
    let requests_per_period: Int
}

struct UpdateWAFRuleRequest: Codable {
    let action: String
    let expression: String
    let description: String?
    let enabled: Bool
    let ratelimit: RateLimitConfig?
    let action_parameters: ActionParameters?
}

struct UpdateWAFRuleResponse: Codable {
    let success: Bool
    let errors: [CloudflareError]?
    let result: Ruleset? // The API returns the whole ruleset when updating a rule
}

struct WAFEntrypointUpdate: Codable {
    let rules: [UpdateWAFRuleRequest]
}
