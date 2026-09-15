import Foundation

protocol AccessServiceProtocol: Sendable {
    func listAccessApps(accountId: String) async throws -> [AccessApp]
    func createAccessApp(accountId: String, name: String, domain: String, type: String, sessionDuration: String) async throws -> AccessApp
    func deleteAccessApp(accountId: String, appId: String) async throws
    func listAccessPolicies(accountId: String, appId: String) async throws -> [AccessPolicy]
    func createAccessPolicy(accountId: String, appId: String, name: String, decision: String) async throws -> AccessPolicy
    func deleteAccessPolicy(accountId: String, appId: String, policyId: String) async throws
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
        let (_, _): (CloudflareIDResponse?, ResultInfo?) = try await client.performRequest(request)
    }

    func listAccessPolicies(accountId: String, appId: String) async throws -> [AccessPolicy] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/access/apps/\(appId)/policies")
        let (policies, _): ([AccessPolicy]?, ResultInfo?) = try await client.performRequest(request)
        return policies ?? []
    }

    /// Creates an Access application policy (POST /accounts/{account_id}/access/apps/{app_id}/policies)
    func createAccessPolicy(accountId: String, appId: String, name: String, decision: String = "allow") async throws -> AccessPolicy {
        let payload: [String: Any] = [
            "name": name,
            "decision": decision,
            "include": [["everyone": [:]]]
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(
            path: "accounts/\(accountId)/access/apps/\(appId)/policies",
            method: "POST",
            body: data
        )
        let (policy, _): (AccessPolicy?, ResultInfo?) = try await client.performRequest(request)
        guard let policy else {
            throw APIError.cloudflareError("Failed to create Access policy.")
        }
        return policy
    }

    /// Deletes an Access application policy (DELETE /accounts/{account_id}/access/apps/{app_id}/policies/{policy_id})
    func deleteAccessPolicy(accountId: String, appId: String, policyId: String) async throws {
        let request = try factory.createAuthenticatedRequest(
            path: "accounts/\(accountId)/access/apps/\(appId)/policies/\(policyId)",
            method: "DELETE"
        )
        _ = try await client.performDataRequest(request)
    }
}
