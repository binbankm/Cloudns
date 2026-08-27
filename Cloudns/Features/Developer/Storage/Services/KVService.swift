import Foundation

/// Cloudflare KV 命名空间与键值对领域服务抽象协议
protocol KVServiceProtocol: Sendable {
    func getKVNamespaces(accountId: String) async throws -> [KVNamespace]
    func listKVNamespaces(accountId: String) async throws -> [KVNamespace]
    func createKVNamespace(accountId: String, title: String) async throws -> KVNamespace
    func deleteKVNamespace(accountId: String, namespaceId: String) async throws
    func getKVKeys(accountId: String, namespaceId: String) async throws -> [KVKey]
    func listKVKeys(accountId: String, namespaceId: String, prefix: String?, limit: Int) async throws -> [KVKey]
    func getKVValue(accountId: String, namespaceId: String, key: String) async throws -> String
    func saveKVValue(accountId: String, namespaceId: String, key: String, value: String, expirationTTL: Int?) async throws
    func deleteKVKey(accountId: String, namespaceId: String, key: String) async throws
}

/// 统一的 Cloudflare KV 命名空间与键值对领域服务
final class KVService: KVServiceProtocol {
    // MARK: - Lifecycle & Dependencies
    static let shared = KVService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private static let safeKVCharSet: CharacterSet = {
        var set = CharacterSet.urlPathAllowed
        set.remove(charactersIn: "/?#[]@!$&'()*+,;=")
        return set
    }()
    
    private init() {}
    
    // MARK: - KV Namespaces & Keys API
    func getKVNamespaces(accountId: String) async throws -> [KVNamespace] {
        try await listKVNamespaces(accountId: accountId)
    }
    
    func listKVNamespaces(accountId: String) async throws -> [KVNamespace] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/storage/kv/namespaces")
        let (namespaces, _): ([KVNamespace]?, ResultInfo?) = try await client.performRequest(request)
        return namespaces ?? []
    }
    
    func createKVNamespace(accountId: String, title: String) async throws -> KVNamespace {
        let payload = ["title": title]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/storage/kv/namespaces", method: "POST", body: data)
        let (ns, _): (KVNamespace?, ResultInfo?) = try await client.performRequest(request)
        guard let item = ns else { throw APIError.cloudflareError("Failed to create KV namespace") }
        return item
    }
    
    func deleteKVNamespace(accountId: String, namespaceId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/storage/kv/namespaces/\(namespaceId)", method: "DELETE")
        struct DeleteRes: Codable { let id: String? }
        let (_, _): (DeleteRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func getKVKeys(accountId: String, namespaceId: String) async throws -> [KVKey] {
        try await listKVKeys(accountId: accountId, namespaceId: namespaceId, prefix: nil, limit: 100)
    }
    
    func listKVKeys(accountId: String, namespaceId: String, prefix: String? = nil, limit: Int = 100) async throws -> [KVKey] {
        var queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]
        if let p = prefix, !p.isEmpty {
            queryItems.append(URLQueryItem(name: "prefix", value: p))
        }
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/storage/kv/namespaces/\(namespaceId)/keys", queryItems: queryItems)
        let (keys, _): ([KVKey]?, ResultInfo?) = try await client.performRequest(request)
        return keys ?? []
    }
    
    func getKVValue(accountId: String, namespaceId: String, key: String) async throws -> String {
        let encodedKey = key.addingPercentEncoding(withAllowedCharacters: Self.safeKVCharSet) ?? key
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/storage/kv/namespaces/\(namespaceId)/values/\(encodedKey)")
        let data = try await client.performDataRequest(request)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    func saveKVValue(accountId: String, namespaceId: String, key: String, value: String, expirationTTL: Int? = nil) async throws {
        let encodedKey = key.addingPercentEncoding(withAllowedCharacters: Self.safeKVCharSet) ?? key
        var queryItems: [URLQueryItem]?
        if let ttl = expirationTTL { queryItems = [URLQueryItem(name: "expiration_ttl", value: "\(ttl)")] }
        let request = try factory.createAuthenticatedRequest(
            path: "accounts/\(accountId)/storage/kv/namespaces/\(namespaceId)/values/\(encodedKey)",
            queryItems: queryItems,
            method: "PUT",
            body: value.data(using: .utf8),
            contentType: "text/plain"
        )
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func deleteKVKey(accountId: String, namespaceId: String, key: String) async throws {
        let encodedKey = key.addingPercentEncoding(withAllowedCharacters: Self.safeKVCharSet) ?? key
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/storage/kv/namespaces/\(namespaceId)/values/\(encodedKey)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
}
