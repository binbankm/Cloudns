import Foundation

/// Cloudflare Hyperdrive 领域服务抽象协议
protocol HyperdriveServiceProtocol: Sendable {
    func listHyperdriveConfigs(accountId: String) async throws -> [HyperdriveConfig]
    func createHyperdriveConfig(accountId: String, payload: HyperdriveCreate) async throws -> HyperdriveConfig
    func deleteHyperdriveConfig(accountId: String, configId: String) async throws
}

/// 统一的 Cloudflare Hyperdrive 领域服务
final class HyperdriveService: HyperdriveServiceProtocol {
    // MARK: - Lifecycle & Dependencies
     = HyperdriveService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    // MARK: - Hyperdrive Configurations API
    (accountId: String) async throws -> [HyperdriveConfig] {
        try await listHyperdriveConfigs(accountId: accountId)
    }
    
    func listHyperdriveConfigs(accountId: String) async throws -> [HyperdriveConfig] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/hyperdrive/configs")
        let (configs, _): ([HyperdriveConfig]?, ResultInfo?) = try await client.performRequest(request)
        return configs ?? []
    }
    
    func createHyperdriveConfig(accountId: String, payload: HyperdriveCreate) async throws -> HyperdriveConfig {
        let data = try JSONEncoder().encode(payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/hyperdrive/configs", method: "POST", body: data)
        let (config, _): (HyperdriveConfig?, ResultInfo?) = try await client.performRequest(request)
        guard let c = config else { throw APIError.cloudflareError("Failed to create Hyperdrive configuration") }
        return c
    }
    
    func deleteHyperdriveConfig(accountId: String, configId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/hyperdrive/configs/\(configId)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
}
