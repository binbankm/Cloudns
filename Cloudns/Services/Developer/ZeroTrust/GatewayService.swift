import Foundation

protocol GatewayServiceProtocol: Sendable {
    func listGatewayRules(accountId: String) async throws -> [GatewayRule]
    func createGatewayRule(accountId: String, name: String, action: String, traffic: String, enabled: Bool, filters: [String]) async throws -> GatewayRule
    func deleteGatewayRule(accountId: String, ruleId: String) async throws
    func toggleGatewayRule(accountId: String, ruleId: String, enabled: Bool) async throws
}

final class GatewayService: GatewayServiceProtocol {
    static let shared = GatewayService()

    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared

    private init() {}

    func getGatewayRules(accountId: String) async throws -> [GatewayRule] {
        try await listGatewayRules(accountId: accountId)
    }

    func listGatewayRules(accountId: String) async throws -> [GatewayRule] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/gateway/rules")
        let (rules, _): ([GatewayRule]?, ResultInfo?) = try await client.performRequest(request)
        return rules ?? []
    }

    func createGatewayRule(
        accountId: String,
        name: String,
        action: String = "block",
        traffic: String,
        enabled: Bool = true,
        filters: [String] = ["dns"]
    ) async throws -> GatewayRule {
        var payload: [String: Any] = [
            "name": name,
            "action": action,
            "traffic": traffic,
            "enabled": enabled
        ]
        if !filters.isEmpty {
            payload["filters"] = filters
        }
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/gateway/rules", method: "POST", body: data)
        let (rule, _): (GatewayRule?, ResultInfo?) = try await client.performRequest(request)
        guard let r = rule else { throw APIError.cloudflareError("Failed to create Gateway rule") }
        return r
    }

    func deleteGatewayRule(accountId: String, ruleId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/gateway/rules/\(ruleId)", method: "DELETE")
        let (_, _): (CloudflareIDResponse?, ResultInfo?) = try await client.performRequest(request)
    }

    /// Toggles active status of a Gateway rule (PATCH /accounts/{account_id}/gateway/rules/{rule_id})
    func toggleGatewayRule(accountId: String, ruleId: String, enabled: Bool) async throws {
        let payload: [String: Any] = ["enabled": enabled]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(
            path: "accounts/\(accountId)/gateway/rules/\(ruleId)",
            method: "PATCH",
            body: data
        )
        let (_, _): (CloudflareIDResponse?, ResultInfo?) = try await client.performRequest(request)
    }
}
