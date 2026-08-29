import Foundation

// MARK: - KV Storage Models

public struct KVNamespace: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let supportsUrlEncoding: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, title
        case supportsUrlEncoding = "supports_url_encoding"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Namespace"
        self.supportsUrlEncoding = try container.decodeIfPresent(Bool.self, forKey: .supportsUrlEncoding)
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

public struct KVKey: Codable, Identifiable, Equatable, Sendable {
    public var id: String { name }
    public let name: String
    public let expiration: Int?
    public let metadata: JSONValue?
    
    public var metadataString: String? {
        metadata?.displayText
    }
    
    public init(name: String, expiration: Int? = nil, metadata: JSONValue? = nil) {
        self.name = name
        self.expiration = expiration
        self.metadata = metadata
    }
    
    public static let placeholders: [KVKey] = (0..<6).map { idx in
        KVKey(name: "user:session:token_\(idx + 1)")
    }
}
