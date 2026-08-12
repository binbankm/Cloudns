import Foundation

struct PageRule: Codable, Identifiable {
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

struct PageRuleTarget: Codable {
    let target: String // usually "url"
    let constraint: PageRuleConstraint
}

struct PageRuleConstraint: Codable {
    let operatorStr: String
    let value: String // The actual URL pattern
    
    enum CodingKeys: String, CodingKey {
        case operatorStr = "operator"
        case value
    }
}

struct PageRuleAction: Codable {
    let id: String // e.g., "always_online", "browser_cache_ttl", "ssl"
    // Since value can be a string, int, or dictionary, we can use a custom decoder or just an AnyCodable if needed.
    // For now, we only need to read the ID and count them to show users what actions are applied.
    // We don't strictly need to parse the `value` field just to display the rule summary.
}
