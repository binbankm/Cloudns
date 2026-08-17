import Foundation

struct IPAccessRule: Codable, Identifiable {
    let id: String
    let mode: String // "block", "challenge", "js_challenge", "managed_challenge", "whitelist" (allow)
    let notes: String?
    let configuration: IPAccessRuleConfiguration
    let created_on: String?
    let modified_on: String?
    
    init(id: String, mode: String = "block", configuration: IPAccessRuleConfiguration, notes: String? = "Block known scrapers") {
        self.id = id
        self.mode = mode
        self.notes = notes
        self.configuration = configuration
        self.created_on = "2024-01-01T00:00:00Z"
        self.modified_on = "2024-01-01T00:00:00Z"
    }
    
    static let placeholders: [IPAccessRule] = [
        IPAccessRule(id: "rule_1", mode: "block", configuration: IPAccessRuleConfiguration(target: "ip", value: "192.0.2.1")),
        IPAccessRule(id: "rule_2", mode: "managed_challenge", configuration: IPAccessRuleConfiguration(target: "country", value: "US")),
        IPAccessRule(id: "rule_3", mode: "whitelist", configuration: IPAccessRuleConfiguration(target: "asn", value: "AS13335")),
        IPAccessRule(id: "rule_4", mode: "block", configuration: IPAccessRuleConfiguration(target: "ip_range", value: "198.51.100.0/24"))
    ]
}

struct IPAccessRuleConfiguration: Codable {
    let target: String // "ip", "ip_range", "asn", "country"
    let value: String // The actual IP, CIDR, AS number, or 2-letter country code
}

struct IPAccessRulesResponse: Codable {
    let success: Bool
    let errors: [CFAPIError]?
    let messages: [String]?
    let result: [IPAccessRule]?
}

struct IPAccessRuleCreateRequest: Codable {
    let mode: String
    let configuration: IPAccessRuleConfiguration
    let notes: String
}

struct IPAccessRuleCreateResponse: Codable {
    let success: Bool
    let errors: [CFAPIError]?
    let result: IPAccessRule?
}
