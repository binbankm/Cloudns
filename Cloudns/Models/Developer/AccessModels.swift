import Foundation

// MARK: - Access Apps & Policies Models

public struct AccessApp: Codable, Identifiable, Equatable {
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
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.name = (try? container.decode(String.self, forKey: .name)) ?? "Access Application"
        self.domain = (try? container.decode(String.self, forKey: .domain)) ?? ""
        self.type = try? container.decodeIfPresent(String.self, forKey: .type)
        self.aud = try? container.decodeIfPresent(String.self, forKey: .aud)
        self.createdAt = try? container.decodeIfPresent(String.self, forKey: .createdAt)
        self.updatedAt = try? container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
    
    public static let placeholders: [AccessApp] = [
        AccessApp(id: "app_1", name: "Internal Admin Dashboard", domain: "admin.internal.net", type: "self_hosted"),
        AccessApp(id: "app_2", name: "Production Grafana", domain: "grafana.internal.net", type: "self_hosted"),
        AccessApp(id: "app_3", name: "Staging SSH Gateway", domain: "ssh.staging.internal.net", type: "ssh")
    ]
}

public struct AccessPolicy: Codable, Identifiable, Equatable {
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
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.name = (try? container.decode(String.self, forKey: .name)) ?? "Access Policy"
        self.decision = (try? container.decode(String.self, forKey: .decision)) ?? "allow"
        self.precedence = try? container.decodeIfPresent(Int.self, forKey: .precedence)
        self.createdAt = try? container.decodeIfPresent(String.self, forKey: .createdAt)
        self.updatedAt = try? container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
}
