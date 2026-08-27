import Foundation

// MARK: - Gateway Rules Models

public struct GatewayRule: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let action: String
    public let enabled: Bool
    public let filters: [String]?
    public let traffic: String?
    public let identity: String?
    public let precedence: Int?
    public let createdAt: String?
    public let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, action, enabled, filters, traffic, identity, precedence
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(id: String, name: String, action: String = "block", enabled: Bool = true, traffic: String? = "dns.security.category in {1}", precedence: Int? = 1) {
        self.id = id
        self.name = name
        self.action = action
        self.enabled = enabled
        self.filters = nil
        self.traffic = traffic
        self.identity = nil
        self.precedence = precedence
        self.createdAt = nil
        self.updatedAt = nil
    }
    
    public static let placeholders: [GatewayRule] = [
        GatewayRule(id: "gw_1", name: "Block Malware & Phishing", action: "block", enabled: true, traffic: "dns.security.category in {1 2 3}"),
        GatewayRule(id: "gw_2", name: "Isolate Social Media", action: "isolate", enabled: true, traffic: "http.request.host in {\"facebook.com\" \"twitter.com\"}")
    ]
}
