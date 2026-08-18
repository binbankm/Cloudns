import Foundation

/// Cloudflare Gateway 网关规则领域服务抽象协议
protocol GatewayServiceProtocol: Sendable {
    func listGatewayRules(accountId: String) async throws -> [GatewayRule]
    func deleteGatewayRule(accountId: String, ruleId: String) async throws
}

/// 统一的 Cloudflare Gateway 网关规则领域服务
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
    
    func deleteGatewayRule(accountId: String, ruleId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/gateway/rules/\(ruleId)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
}
