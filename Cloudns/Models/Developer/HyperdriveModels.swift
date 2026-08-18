import Foundation

// MARK: - Hyperdrive Models

public struct HyperdriveConfig: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let origin: HyperdriveOrigin?
    public let caching: HyperdriveCaching?
    public let createdOn: String?
    public let modifiedOn: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, origin, caching
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
    }
    
    public init(id: String, name: String, origin: HyperdriveOrigin? = nil, caching: HyperdriveCaching? = nil, createdOn: String? = nil, modifiedOn: String? = nil) {
        self.id = id
        self.name = name
        self.origin = origin
        self.caching = caching
        self.createdOn = createdOn
        self.modifiedOn = modifiedOn
    }
    
    public static let placeholders: [HyperdriveConfig] = [
        HyperdriveConfig(id: "hd_1", name: "prod-postgres-hyperdrive", origin: HyperdriveOrigin(host: "db.aws.example.com", port: 5432, database: "users", user: "app", scheme: "postgres")),
        HyperdriveConfig(id: "hd_2", name: "staging-postgres-accelerator", origin: HyperdriveOrigin(host: "staging-db.example.com", port: 5432, database: "staging", user: "app", scheme: "postgres"))
    ]
}

public struct HyperdriveOrigin: Codable, Equatable, Sendable {
    public let host: String?
    public let port: Int?
    public let database: String?
    public let user: String?
    public let scheme: String?
    
    public init(host: String? = nil, port: Int? = nil, database: String? = nil, user: String? = nil, scheme: String? = nil) {
        self.host = host
        self.port = port
        self.database = database
        self.user = user
        self.scheme = scheme
    }
}

public struct HyperdriveCaching: Codable, Equatable, Sendable {
    public let disabled: Bool?
    public let maxAge: Int?
    public let staleWhileRevalidate: Int?
    
    enum CodingKeys: String, CodingKey {
        case disabled
        case maxAge = "max_age"
        case staleWhileRevalidate = "stale_while_revalidate"
    }
    
    public init(disabled: Bool? = nil, maxAge: Int? = nil, staleWhileRevalidate: Int? = nil) {
        self.disabled = disabled
        self.maxAge = maxAge
        self.staleWhileRevalidate = staleWhileRevalidate
    }
}

public struct HyperdriveCreate: Codable, Sendable {
    public let name: String
    public let origin: HyperdriveOriginInput
    public let caching: HyperdriveCaching?
    
    public init(name: String, origin: HyperdriveOriginInput, caching: HyperdriveCaching? = nil) {
        self.name = name
        self.origin = origin
        self.caching = caching
    }
}

public struct HyperdriveOriginInput: Codable, Sendable {
    public let host: String
    public let port: Int
    public let database: String
    public let user: String
    public let password: String
    public let scheme: String
    
    public init(host: String, port: Int, database: String, user: String, password: String, scheme: String = "postgres") {
        self.host = host
        self.port = port
        self.database = database
        self.user = user
        self.password = password
        self.scheme = scheme
    }
}

public struct HyperdrivePatch: Codable, Sendable {
    public let name: String?
    public let origin: HyperdriveOriginInput?
    public let caching: HyperdriveCaching?
    
    public init(name: String? = nil, origin: HyperdriveOriginInput? = nil, caching: HyperdriveCaching? = nil) {
        self.name = name
        self.origin = origin
        self.caching = caching
    }
}
