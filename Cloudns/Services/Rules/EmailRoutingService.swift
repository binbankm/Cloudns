import Foundation

/// Cloudflare Email Routing 邮件路由领域服务抽象协议
protocol EmailRoutingServiceProtocol: Sendable {
    func getEmailRoutingSettings(zoneId: String) async throws -> EmailRoutingSettings?
    func getEmailRoutingRules(zoneId: String) async throws -> [EmailRoutingRule]
    func getEmailDestinations(accountId: String) async throws -> [EmailDestinationAddress]
    func createEmailRoutingRule(zoneId: String, rule: EmailRoutingRuleInput) async throws -> EmailRoutingRule
    func deleteEmailRoutingRule(zoneId: String, ruleId: String) async throws
}

/// 统一的 Cloudflare Email Routing 邮件路由领域服务
final class EmailRoutingService: EmailRoutingServiceProtocol {
    static let shared = EmailRoutingService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func getEmailRoutingSettings(zoneId: String) async throws -> EmailRoutingSettings? {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/email/routing")
        let (settings, _): (EmailRoutingSettings?, ResultInfo?) = try await client.performRequest(request)
        return settings
    }
    
    func getEmailRoutingRules(zoneId: String) async throws -> [EmailRoutingRule] {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/email/routing/rules")
        let (rules, _): ([EmailRoutingRule]?, ResultInfo?) = try await client.performRequest(request)
        return rules ?? []
    }
    
    func getEmailDestinations(accountId: String) async throws -> [EmailDestinationAddress] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/email/routing/addresses")
        let (destinations, _): ([EmailDestinationAddress]?, ResultInfo?) = try await client.performRequest(request)
        return destinations ?? []
    }
    
    func createEmailRoutingRule(zoneId: String, rule: EmailRoutingRuleInput) async throws -> EmailRoutingRule {
        let encoder = JSONEncoder()
        let data = try encoder.encode(rule)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/email/routing/rules", method: "POST", body: data)
        let (created, _): (EmailRoutingRule?, ResultInfo?) = try await client.performRequest(request)
        guard let r = created else { throw APIError.cloudflareError("Failed to create email routing rule.") }
        return r
    }
    
    func deleteEmailRoutingRule(zoneId: String, ruleId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/email/routing/rules/\(ruleId)", method: "DELETE")
        struct DeleteResult: Codable { let id: String? }
        let (_, _): (DeleteResult?, ResultInfo?) = try await client.performRequest(request)
    }
}
