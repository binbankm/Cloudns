import Foundation

struct EmailRoutingSettings: Codable, Equatable, Sendable {
    let id: String?
    let tag: String?
    let name: String?
    let enabled: Bool?
    let status: String?
    
    var isEnabled: Bool { enabled ?? false }
}

struct EmailRoutingMatcher: Codable, Equatable, Sendable {
    let type: String
    let field: String?
    let value: String?
}

struct EmailRoutingAction: Codable, Equatable, Sendable {
    let type: String
    let value: [String]?
}

struct EmailRoutingRule: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let tag: String?
    let name: String?
    let enabled: Bool?
    let priority: Int?
    let matchers: [EmailRoutingMatcher]
    let actions: [EmailRoutingAction]
    
    enum CodingKeys: String, CodingKey {
        case id, tag, name, enabled, priority, matchers, actions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.tag = try container.decodeIfPresent(String.self, forKey: .tag)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)
        self.priority = try container.decodeIfPresent(Int.self, forKey: .priority)
        self.matchers = try container.decodeIfPresent([EmailRoutingMatcher].self, forKey: .matchers) ?? []
        self.actions = try container.decodeIfPresent([EmailRoutingAction].self, forKey: .actions) ?? []
    }
    
    init(id: String, tag: String? = nil, name: String? = nil, enabled: Bool? = true, priority: Int? = 0, matchers: [EmailRoutingMatcher] = [], actions: [EmailRoutingAction] = []) {
        self.id = id
        self.tag = tag
        self.name = name
        self.enabled = enabled
        self.priority = priority
        self.matchers = matchers
        self.actions = actions
    }
    
    var isEnabled: Bool { enabled ?? false }
    
    var matchAddress: String? {
        matchers.first(where: { $0.type == "literal" })?.value
    }
    
    var actionSummary: String {
        guard let action = actions.first else { return "No action" }
        switch action.type {
        case "forward": return action.value?.joined(separator: ", ") ?? "Forward"
        case "worker": return action.value?.first.map { "Worker · \($0)" } ?? "Worker"
        case "drop": return "Drop"
        default: return action.type
        }
    }
    
    var forwardTo: String? {
        actions.first(where: { $0.type == "forward" })?.value?.joined(separator: ", ")
    }
    
    var isCatchAll: Bool { matchers.contains { $0.type == "all" } }
    
}

struct EmailRoutingRuleInput: Codable, Sendable {
    let name: String?
    let enabled: Bool
    let matchers: [EmailRoutingMatcher]
    let actions: [EmailRoutingAction]
    
    static func forward(name: String?, to matchAddress: String, destination: String, enabled: Bool) -> EmailRoutingRuleInput {
        .init(
            name: name,
            enabled: enabled,
            matchers: [.init(type: "literal", field: "to", value: matchAddress)],
            actions: [.init(type: "forward", value: [destination])]
        )
    }
}

struct EmailDestinationAddress: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let tag: String?
    let email: String
    let verified: String?
    let created: String?
    
    var isVerified: Bool { verified != nil }
}

struct EmailDestinationCreate: Codable, Sendable {
    let email: String
}
