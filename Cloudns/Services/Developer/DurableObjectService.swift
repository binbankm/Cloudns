import Foundation

/// 统一的 Cloudflare Durable Objects 领域服务
final class DurableObjectService {
    static let shared = DurableObjectService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func listDONamespaces(accountId: String) async throws -> [DurableObjectNamespace] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/durable_objects/namespaces")
        let (ns, _): ([DurableObjectNamespace]?, ResultInfo?) = try await client.performRequest(request)
        return ns ?? []
    }
    
    func listDOObjects(accountId: String, namespaceId: String, cursor: String? = nil, limit: Int = 100) async throws -> (items: [DurableObjectInstance], cursor: String?) {
        var queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]
        if let c = cursor, !c.isEmpty { queryItems.append(URLQueryItem(name: "cursor", value: c)) }
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/durable_objects/namespaces/\(namespaceId)/objects", queryItems: queryItems)
        let (objs, info): ([DurableObjectInstance]?, ResultInfo?) = try await client.performRequest(request)
        return (objs ?? [], info?.cursors?.after)
    }
}
