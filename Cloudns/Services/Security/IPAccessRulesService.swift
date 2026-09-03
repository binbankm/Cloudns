import Foundation

/// Protocol defining Cloudflare IP Access Rules domain service
protocol IPAccessRulesServiceProtocol: Sendable {
    func getIPAccessRules(zoneId: String, page: Int, perPage: Int) async throws -> ([IPAccessRule], ResultInfo?)
    func createIPAccessRule(zoneId: String, mode: String, target: String, value: String, notes: String?) async throws -> IPAccessRule
    func deleteIPAccessRule(zoneId: String, ruleId: String) async throws
}

extension IPAccessRulesServiceProtocol {
    func getIPAccessRules(zoneId: String, page: Int = 1, perPage: Int = 50) async throws -> ([IPAccessRule], ResultInfo?) {
        try await getIPAccessRules(zoneId: zoneId, page: page, perPage: perPage)
    }
}

/// Concrete domain service for Cloudflare IP Access Rules
final class IPAccessRulesService: IPAccessRulesServiceProtocol {
    static let shared = IPAccessRulesService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func getIPAccessRules(zoneId: String, page: Int = 1, perPage: Int = 50) async throws -> ([IPAccessRule], ResultInfo?) {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/firewall/access_rules/rules", queryItems: queryItems)
        let (rules, info): ([IPAccessRule]?, ResultInfo?) = try await client.performRequest(request)
        return (rules ?? [], info)
    }
    
    func createIPAccessRule(zoneId: String, mode: String, target: String, value: String, notes: String?) async throws -> IPAccessRule {
        let config: [String: String] = [
            "target": target,
            "value": value
        ]
        var payload: [String: Any] = [
            "mode": mode,
            "configuration": config
        ]
        if let n = notes, !n.isEmpty {
            payload["notes"] = n
        }
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/firewall/access_rules/rules", method: "POST", body: data)
        let (rule, _): (IPAccessRule?, ResultInfo?) = try await client.performRequest(request)
        guard let r = rule else { throw APIError.cloudflareError("Failed to create IP rule") }
        return r
    }
    
    func deleteIPAccessRule(zoneId: String, ruleId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/firewall/access_rules/rules/\(ruleId)", method: "DELETE")
        struct DeleteRes: Codable { let id: String? }
        let (_, _): (DeleteRes?, ResultInfo?) = try await client.performRequest(request)
    }
}
