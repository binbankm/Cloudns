import Foundation

protocol BulkRedirectServiceProtocol: Sendable {
    func listRedirectLists(accountId: String) async throws -> [RedirectList]
    func createRedirectList(accountId: String, name: String, description: String?) async throws -> RedirectList
    func deleteRedirectList(accountId: String, listId: String) async throws
    func listRedirectListItems(accountId: String, listId: String) async throws -> [RedirectListItem]
    func createRedirectListItems(accountId: String, listId: String, items: [RedirectItemDetail]) async throws -> String
    func deleteRedirectListItems(accountId: String, listId: String, itemIds: [String]) async throws -> String
}

final class BulkRedirectService: BulkRedirectServiceProtocol {
    static let shared = BulkRedirectService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func listRedirectLists(accountId: String) async throws -> [RedirectList] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/rules/lists")
        let (lists, _): ([RedirectList]?, ResultInfo?) = try await client.performRequest(request)
        return (lists ?? []).filter { $0.kind == "redirect" }
    }
    
    func createRedirectList(accountId: String, name: String, description: String?) async throws -> RedirectList {
        var payload: [String: Any] = ["name": name, "kind": "redirect"]
        if let d = description { payload["description"] = d }
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/rules/lists", method: "POST", body: data)
        let (list, _): (RedirectList?, ResultInfo?) = try await client.performRequest(request)
        guard let l = list else { throw APIError.invalidResponse }
        return l
    }
    
    func deleteRedirectList(accountId: String, listId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/rules/lists/\(listId)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func listRedirectListItems(accountId: String, listId: String) async throws -> [RedirectListItem] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/rules/lists/\(listId)/items")
        let (items, _): ([RedirectListItem]?, ResultInfo?) = try await client.performRequest(request)
        return items ?? []
    }
    
    func createRedirectListItems(accountId: String, listId: String, items: [RedirectItemDetail]) async throws -> String {
        struct ItemWrapper: Codable { let redirect: RedirectItemDetail }
        let data = try JSONEncoder().encode(items.map { ItemWrapper(redirect: $0) })
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/rules/lists/\(listId)/items", method: "POST", body: data)
        let (ref, _): (BulkOperationRef?, ResultInfo?) = try await client.performRequest(request)
        guard let op = ref?.operationId else { throw APIError.invalidResponse }
        return op
    }
    
    func deleteRedirectListItems(accountId: String, listId: String, itemIds: [String]) async throws -> String {
        struct ItemRef: Codable { let id: String }
        struct DeleteBody: Codable { let items: [ItemRef] }
        let data = try JSONEncoder().encode(DeleteBody(items: itemIds.map { ItemRef(id: $0) }))
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/rules/lists/\(listId)/items", method: "DELETE", body: data)
        let (ref, _): (BulkOperationRef?, ResultInfo?) = try await client.performRequest(request)
        guard let op = ref?.operationId else { throw APIError.invalidResponse }
        return op
    }
}
