import Foundation

struct IPAccessRule: Codable, Identifiable {
    let id: String
    let mode: String // "block", "challenge", "js_challenge", "managed_challenge", "whitelist" (allow)
    let notes: String?
    let configuration: IPAccessRuleConfiguration
    let created_on: String?
    let modified_on: String?
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
