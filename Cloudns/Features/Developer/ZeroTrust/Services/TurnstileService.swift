import Foundation

/// Cloudflare Turnstile 验证码领域服务抽象协议
protocol TurnstileServiceProtocol: Sendable {
    func getTurnstileWidgets(accountId: String) async throws -> [TurnstileWidget]
    func createTurnstileWidget(accountId: String, input: TurnstileCreateInput) async throws -> TurnstileWidget
    func updateTurnstileWidget(accountId: String, sitekey: String, input: TurnstileUpdateInput) async throws -> TurnstileWidget
    func deleteTurnstileWidget(accountId: String, sitekey: String) async throws
    func rotateTurnstileSecret(accountId: String, sitekey: String, invalidateImmediately: Bool) async throws -> String
}

/// 统一的 Cloudflare Turnstile 验证码领域服务
final class TurnstileService: TurnstileServiceProtocol {
    // MARK: - Lifecycle & Dependencies
    static let shared = TurnstileService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    // MARK: - Turnstile API
    func getTurnstileWidgets(accountId: String) async throws -> [TurnstileWidget] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/challenges/widgets")
        let (widgets, _): ([TurnstileWidget]?, ResultInfo?) = try await client.performRequest(request)
        return widgets ?? []
    }
    
    func createTurnstileWidget(accountId: String, input: TurnstileCreateInput) async throws -> TurnstileWidget {
        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/challenges/widgets", method: "POST", body: data)
        let (widget, _): (TurnstileWidget?, ResultInfo?) = try await client.performRequest(request)
        guard let w = widget else { throw APIError.cloudflareError("Failed to create Turnstile widget") }
        return w
    }
    
    func updateTurnstileWidget(accountId: String, sitekey: String, input: TurnstileUpdateInput) async throws -> TurnstileWidget {
        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/challenges/widgets/\(sitekey)", method: "PATCH", body: data)
        let (widget, _): (TurnstileWidget?, ResultInfo?) = try await client.performRequest(request)
        guard let w = widget else { throw APIError.cloudflareError("Failed to update Turnstile widget") }
        return w
    }
    
    func deleteTurnstileWidget(accountId: String, sitekey: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/challenges/widgets/\(sitekey)", method: "DELETE")
        struct DeleteRes: Codable { let id: String? }
        let (_, _): (DeleteRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func rotateTurnstileSecret(accountId: String, sitekey: String, invalidateImmediately: Bool = false) async throws -> String {
        let payload = ["invalidate_immediately": invalidateImmediately]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/challenges/widgets/\(sitekey)/rotate_secret", method: "POST", body: data)
        struct RotateRes: Codable { let secret: String? }
        let (res, _): (RotateRes?, ResultInfo?) = try await client.performRequest(request)
        guard let sec = res?.secret else { throw APIError.cloudflareError("Failed to rotate secret") }
        return sec
    }
}
