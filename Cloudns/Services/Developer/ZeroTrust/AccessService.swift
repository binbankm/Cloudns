import Foundation

protocol AccessServiceProtocol: Sendable {
    func listAccessApps(accountId: String) async throws -> [AccessApp]
    func createAccessApp(accountId: String, name: String, domain: String, type: String, sessionDuration: String) async throws -> AccessApp
    func deleteAccessApp(accountId: String, appId: String) async throws
    func listAccessPolicies(accountId: String, appId: String) async throws -> [AccessPolicy]
}

final class AccessService: AccessServiceProtocol {
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
    
    func createAccessApp(accountId: String, name: String, domain: String, type: String = "self_hosted", sessionDuration: String = "24h") async throws -> AccessApp {
        let payload: [String: Any] = [
            "name": name,
            "domain": domain,
            "type": type,
            "session_duration": sessionDuration
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/access/apps", method: "POST", body: data)
        let (app, _): (AccessApp?, ResultInfo?) = try await client.performRequest(request)
        guard let a = app else { throw APIError.cloudflareError("Failed to create Access application") }
        return a
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
