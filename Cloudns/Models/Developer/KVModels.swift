import Foundation

// MARK: - KV Storage Models

public struct KVNamespace: Codable, Identifiable, Equatable {
    public let id: String
    public let title: String
    public let supportsUrlEncoding: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, title
        case supportsUrlEncoding = "supports_url_encoding"
    }
    
    public init(id: String, title: String, supportsUrlEncoding: Bool? = true) {
        self.id = id
        self.title = title
        self.supportsUrlEncoding = supportsUrlEncoding
    }
    
    public static let placeholders: [KVNamespace] = (0..<4).map { idx in
        KVNamespace(id: "kv-ns-uuid-\(idx + 1)-abcd", title: "SESSION_CACHE_\(idx + 1)")
    }
}

public struct KVKey: Codable, Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let expiration: Int?
    public let metadata: String?
    
    public init(name: String, expiration: Int? = nil, metadata: String? = nil) {
        self.name = name
        self.expiration = expiration
        self.metadata = metadata
    }
    
    public static let placeholders: [KVKey] = (0..<6).map { idx in
        KVKey(name: "user:session:token_\(idx + 1)")
    }
}
