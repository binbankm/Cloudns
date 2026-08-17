import Foundation

/// 统一的 Cloudflare Access 访问控制领域服务
final class AccessService {
    static let shared = AccessService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func getAccessApps(accountId: String) async throws -> [AccessApp] {
        try await listAccessApps(accountId: accountId)
    }
    
    func listAccessApps(accountId: String) async throws -> [AccessApp] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/access/apps")
        let (apps, _): ([AccessApp]?, ResultInfo?) = try await client.performRequest(request)
        return apps ?? []
    }
    
    func deleteAccessApp(accountId: String, appId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/access/apps/\(appId)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func listAccessPolicies(accountId: String, appId: String) async throws -> [AccessPolicy] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/access/apps/\(appId)/policies")
        let (policies, _): ([AccessPolicy]?, ResultInfo?) = try await client.performRequest(request)
        return policies ?? []
    }
}
