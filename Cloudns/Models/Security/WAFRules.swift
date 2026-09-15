import Foundation

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
    let actionParameters: ActionParameters?

    var action_parameters: ActionParameters? {
        actionParameters
    }

    enum CodingKeys: String, CodingKey {
        case id, action, expression, description, enabled, ratelimit
        case actionParameters = "action_parameters"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        action = try container.decodeIfPresent(String.self, forKey: .action) ?? "block"
        expression = try container.decodeIfPresent(String.self, forKey: .expression) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        ratelimit = try container.decodeIfPresent(RateLimitConfig.self, forKey: .ratelimit)
        actionParameters = try container.decodeIfPresent(ActionParameters.self, forKey: .actionParameters)
    }

    init(
        id: String,
        action: String = "block",
        expression: String = "(http.request.uri.path contains \"/wp-admin\")",
        description: String? = "Block Admin Endpoint Access",
        enabled: Bool = true,
        ratelimit: RateLimitConfig? = nil,
        actionParameters: ActionParameters? = nil
    ) {
        self.id = id
        self.action = action
        self.expression = expression
        self.description = description
        self.enabled = enabled
        self.ratelimit = ratelimit
        self.actionParameters = actionParameters
    }
}

struct RateLimitConfig: Codable, Equatable, Sendable {
    let characteristics: [String]?
    let mitigationTimeout: Int?
    let period: Int
    let requestsPerPeriod: Int

    var mitigation_timeout: Int? {
        mitigationTimeout
    }

    var requests_per_period: Int {
        requestsPerPeriod
    }

    enum CodingKeys: String, CodingKey {
        case characteristics, period
        case mitigationTimeout = "mitigation_timeout"
        case requestsPerPeriod = "requests_per_period"
    }

    init(characteristics: [String]? = nil, mitigationTimeout: Int? = nil, period: Int, requestsPerPeriod: Int) {
        self.characteristics = characteristics
        self.mitigationTimeout = mitigationTimeout
        self.period = period
        self.requestsPerPeriod = requestsPerPeriod
    }
}

struct UpdateWAFRuleRequest: Codable, Equatable, Sendable {
    let action: String
    let expression: String
    let description: String?
    let enabled: Bool
    let ratelimit: RateLimitConfig?
    let actionParameters: ActionParameters?

    enum CodingKeys: String, CodingKey {
        case action, expression, description, enabled, ratelimit
        case actionParameters = "action_parameters"
    }
}

struct WAFEntrypointUpdate: Codable, Equatable, Sendable {
    let rules: [UpdateWAFRuleRequest]
}
