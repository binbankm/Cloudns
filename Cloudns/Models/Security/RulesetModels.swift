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

    enum CodingKeys: String, CodingKey {
        case id, action, expression, description, enabled, ratelimit, action_parameters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        action = try container.decodeIfPresent(String.self, forKey: .action) ?? "block"
        expression = try container.decodeIfPresent(String.self, forKey: .expression) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        ratelimit = try container.decodeIfPresent(RateLimitConfig.self, forKey: .ratelimit)
        action_parameters = try container.decodeIfPresent(ActionParameters.self, forKey: .action_parameters)
    }

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

public struct RulesetOverride: Codable, Equatable, Sendable {
    public let action: String?
    public let enabled: Bool?
    public let sensitivity_level: String?
    public let rules: [RuleOverrideItem]?
    public let categories: [CategoryOverrideItem]?

    public init(action: String? = nil, enabled: Bool? = nil, sensitivity_level: String? = nil, rules: [RuleOverrideItem]? = nil, categories: [CategoryOverrideItem]? = nil) {
        self.action = action
        self.enabled = enabled
        self.sensitivity_level = sensitivity_level
        self.rules = rules
        self.categories = categories
    }
}

public struct RuleOverrideItem: Codable, Equatable, Sendable {
    public let id: String
    public let action: String?
    public let enabled: Bool?

    public init(id: String, action: String? = nil, enabled: Bool? = nil) {
        self.id = id
        self.action = action
        self.enabled = enabled
    }
}

public struct CategoryOverrideItem: Codable, Equatable, Sendable {
    public let category: String
    public let action: String?
    public let enabled: Bool?

    public init(category: String, action: String? = nil, enabled: Bool? = nil) {
        self.category = category
        self.action = action
        self.enabled = enabled
    }
}
