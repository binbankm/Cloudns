import Foundation

// MARK: - Access Apps & Policies Models

public struct AccessApp: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let domain: String
    public let type: String?
    public let aud: String?
    public let createdAt: String?
    public let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, domain, type, aud
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(id: String, name: String, domain: String, type: String? = "self_hosted", aud: String? = nil, createdAt: String? = nil, updatedAt: String? = nil) {
        self.id = id
        self.name = name
        self.domain = domain
        self.type = type
        self.aud = aud
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        name = (try? container.decode(String.self, forKey: .name)) ?? "Access Application"
        domain = (try? container.decode(String.self, forKey: .domain)) ?? ""
        type = try? container.decodeIfPresent(String.self, forKey: .type)
        aud = try? container.decodeIfPresent(String.self, forKey: .aud)
        createdAt = try? container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try? container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
}

public struct AccessPolicy: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let decision: String
    public let precedence: Int?
    public let createdAt: String?
    public let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, decision, precedence
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(id: String, name: String, decision: String, precedence: Int? = nil, createdAt: String? = nil, updatedAt: String? = nil) {
        self.id = id
        self.name = name
        self.decision = decision
        self.precedence = precedence
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        name = (try? container.decode(String.self, forKey: .name)) ?? "Access Policy"
        decision = (try? container.decode(String.self, forKey: .decision)) ?? "allow"
        precedence = try? container.decodeIfPresent(Int.self, forKey: .precedence)
        createdAt = try? container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try? container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
}
