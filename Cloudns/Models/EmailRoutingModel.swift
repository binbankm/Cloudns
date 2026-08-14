import Foundation

struct EmailRoutingSettings: Codable {
    let id: String?
    let tag: String?
    let name: String?
    let enabled: Bool?
    let status: String?
    
    var isEnabled: Bool { enabled ?? false }
}

struct EmailRoutingMatcher: Codable {
    let type: String
    let field: String?
    let value: String?
}

struct EmailRoutingAction: Codable {
    let type: String
    let value: [String]?
}

struct EmailRoutingRule: Codable, Identifiable {
    let id: String
    let tag: String?
    let name: String?
    let enabled: Bool?
    let priority: Int?
    let matchers: [EmailRoutingMatcher]
    let actions: [EmailRoutingAction]
    
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
    
    var isCatchAll: Bool { matchers.contains { $0.type == "all" } }
}

struct EmailRoutingRuleInput: Codable {
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

struct EmailDestinationAddress: Codable, Identifiable {
    let id: String
    let tag: String?
    let email: String
    let verified: String?
    let created: String?
    
    var isVerified: Bool { verified != nil }
}

struct EmailDestinationCreate: Codable {
    let email: String
}
