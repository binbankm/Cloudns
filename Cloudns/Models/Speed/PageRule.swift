import Foundation

struct PageRule: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let targets: [PageRuleTarget]
    let actions: [PageRuleAction]
    let priority: Int
    var status: String // "active" or "disabled"
    let createdOn: String?
    let modifiedOn: String?
    
    enum CodingKeys: String, CodingKey {
        case id, targets, actions, priority, status
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
    }
}

struct PageRuleTarget: Codable, Equatable, Sendable {
    let target: String // usually "url"
    let constraint: PageRuleConstraint
}

struct PageRuleConstraint: Codable, Equatable, Sendable {
    let operatorStr: String
    let value: String // The actual URL pattern
    
    enum CodingKeys: String, CodingKey {
        case operatorStr = "operator"
        case value
    }
}

struct PageRuleAction: Codable, Equatable, Sendable {
    let id: String // e.g., "always_online", "browser_cache_ttl", "ssl"
}
