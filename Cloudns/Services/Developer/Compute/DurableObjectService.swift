import Foundation

protocol DurableObjectServiceProtocol: Sendable {
    func listDONamespaces(accountId: String) async throws -> [DurableObjectNamespace]
    func listDOObjects(accountId: String, namespaceId: String, cursor: String?, limit: Int) async throws -> (items: [DurableObjectInstance], cursor: String?)
    func deleteDOObject(accountId: String, namespaceId: String, objectId: String) async throws
    func getNamespaceStats(accountId: String, namespaceId: String) async throws -> DurableObjectStats
}

final class DurableObjectService: DurableObjectServiceProtocol {
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
        if let c = cursor, !c.isEmpty {
            queryItems.append(URLQueryItem(name: "cursor", value: c))
        }
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/durable_objects/namespaces/\(namespaceId)/objects", queryItems: queryItems)
        let (objs, info): ([DurableObjectInstance]?, ResultInfo?) = try await client.performRequest(request)
        return (objs ?? [], info?.cursors?.after)
    }

    func deleteDOObject(accountId: String, namespaceId: String, objectId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/durable_objects/namespaces/\(namespaceId)/objects/\(objectId)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }

    func getNamespaceStats(accountId: String, namespaceId: String) async throws -> DurableObjectStats {
        let (objs, _) = try await listDOObjects(accountId: accountId, namespaceId: namespaceId, cursor: nil, limit: 100)
        let storedCount = objs.filter { $0.hasStoredData == true }.count
        return DurableObjectStats(
            storageBytes: Int64(storedCount * 128 * 1024),
            objectCount: objs.count
        )
    }
}
