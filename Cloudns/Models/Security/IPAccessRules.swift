import Foundation

struct IPAccessRule: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let mode: String // "block", "challenge", "js_challenge", "managed_challenge", "whitelist" (allow)
    let notes: String?
    let configuration: IPAccessRuleConfiguration
    let createdOn: String?
    let modifiedOn: String?

    var created_on: String? {
        createdOn
    }

    var modified_on: String? {
        modifiedOn
    }

    enum CodingKeys: String, CodingKey {
        case id, mode, notes, configuration
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
    }

    init(id: String, mode: String = "block", configuration: IPAccessRuleConfiguration, notes: String? = "Block known scrapers") {
        self.id = id
        self.mode = mode
        self.notes = notes
        self.configuration = configuration
        createdOn = "2024-01-01T00:00:00Z"
        modifiedOn = "2024-01-01T00:00:00Z"
    }
}

struct IPAccessRuleConfiguration: Codable, Equatable, Sendable {
    let target: String // "ip", "ip_range", "asn", "country"
    let value: String // The actual IP, CIDR, AS number, or 2-letter country code
}
