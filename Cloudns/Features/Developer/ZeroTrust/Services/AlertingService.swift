import Foundation

/// Cloudflare Alerting 告警与通知策略领域服务抽象协议
protocol AlertingServiceProtocol: Sendable {
    func listAvailableAlertTypes(accountId: String) async throws -> [AlertingAvailableType]
    func listAlertingWebhooks(accountId: String) async throws -> [AlertingWebhookDestination]
    func listAlertingPolicies(accountId: String) async throws -> [AlertingPolicy]
    func deleteAlertingPolicy(accountId: String, policyId: String) async throws
}

/// 统一的 Cloudflare Alerting 告警与通知策略领域服务
final class AlertingService: AlertingServiceProtocol {
    // MARK: - Lifecycle & Dependencies
    static let shared = AlertingService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func listAvailableAlertTypes(accountId: String) async throws -> [AlertingAvailableType] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/alerting/v3/available_alerts")
        let (types, _): ([AlertingAvailableType]?, ResultInfo?) = try await client.performRequest(request)
        return types ?? []
    }
    
    func listAlertingWebhooks(accountId: String) async throws -> [AlertingWebhookDestination] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/alerting/v3/destinations/webhooks")
        let (hooks, _): ([AlertingWebhookDestination]?, ResultInfo?) = try await client.performRequest(request)
        return hooks ?? []
    }
    
    func listAlertingPolicies(accountId: String) async throws -> [AlertingPolicy] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/alerting/v3/policies")
        let (policies, _): ([AlertingPolicy]?, ResultInfo?) = try await client.performRequest(request)
        return policies ?? []
    }
    
    func deleteAlertingPolicy(accountId: String, policyId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/alerting/v3/policies/\(policyId)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
}
