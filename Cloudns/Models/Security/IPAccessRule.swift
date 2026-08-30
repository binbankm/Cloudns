import Foundation

struct IPAccessRule: Codable, Identifiable, Equatable, Sendable {
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
    
}

struct IPAccessRuleConfiguration: Codable, Equatable, Sendable {
    let target: String // "ip", "ip_range", "asn", "country"
    let value: String // The actual IP, CIDR, AS number, or 2-letter country code
}

struct IPAccessRulesResponse: Codable, Sendable {
    let success: Bool
    let errors: [CFAPIError]?
    let messages: [String]?
    let result: [IPAccessRule]?
}

struct IPAccessRuleCreateRequest: Codable, Sendable {
    let mode: String
    let configuration: IPAccessRuleConfiguration
    let notes: String
}

struct IPAccessRuleCreateResponse: Codable, Sendable {
    let success: Bool
    let errors: [CFAPIError]?
    let result: IPAccessRule?
}
