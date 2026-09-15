import Foundation

protocol HyperdriveServiceProtocol: Sendable {
    func listHyperdriveConfigs(accountId: String) async throws -> [HyperdriveConfig]
    func getHyperdriveConfig(accountId: String, configId: String) async throws -> HyperdriveConfig
    func createHyperdriveConfig(accountId: String, payload: HyperdriveCreate) async throws -> HyperdriveConfig
    func updateHyperdriveConfig(accountId: String, configId: String, payload: HyperdrivePatch) async throws -> HyperdriveConfig
    func deleteHyperdriveConfig(accountId: String, configId: String) async throws
}

final class HyperdriveService: HyperdriveServiceProtocol {
    static let shared = HyperdriveService()

    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared

    private init() {}

    func getHyperdriveConfigs(accountId: String) async throws -> [HyperdriveConfig] {
        try await listHyperdriveConfigs(accountId: accountId)
    }

    func listHyperdriveConfigs(accountId: String) async throws -> [HyperdriveConfig] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/hyperdrive/configs")
        let (configs, _): ([HyperdriveConfig]?, ResultInfo?) = try await client.performRequest(request)
        return configs ?? []
    }

    /// Fetches single Hyperdrive configuration details (GET /accounts/{account_id}/hyperdrive/configs/{config_id})
    func getHyperdriveConfig(accountId: String, configId: String) async throws -> HyperdriveConfig {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/hyperdrive/configs/\(configId)")
        let (config, _): (HyperdriveConfig?, ResultInfo?) = try await client.performRequest(request)
        guard let config else {
            throw APIError.cloudflareError("Hyperdrive configuration not found.")
        }
        return config
    }

    func createHyperdriveConfig(accountId: String, payload: HyperdriveCreate) async throws -> HyperdriveConfig {
        let data = try JSONEncoder().encode(payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/hyperdrive/configs", method: "POST", body: data)
        let (config, _): (HyperdriveConfig?, ResultInfo?) = try await client.performRequest(request)
        guard let c = config else { throw APIError.cloudflareError("Failed to create Hyperdrive configuration") }
        return c
    }

    /// Updates existing Hyperdrive configuration (PUT /accounts/{account_id}/hyperdrive/configs/{config_id})
    func updateHyperdriveConfig(accountId: String, configId: String, payload: HyperdrivePatch) async throws -> HyperdriveConfig {
        let data = try JSONEncoder().encode(payload)
        let request = try factory.createAuthenticatedRequest(
            path: "accounts/\(accountId)/hyperdrive/configs/\(configId)",
            method: "PUT",
            body: data
        )
        let (config, _): (HyperdriveConfig?, ResultInfo?) = try await client.performRequest(request)
        guard let config else {
            throw APIError.cloudflareError("Failed to update Hyperdrive configuration.")
        }
        return config
    }

    func deleteHyperdriveConfig(accountId: String, configId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/hyperdrive/configs/\(configId)", method: "DELETE")
        let (_, _): (CloudflareIDResponse?, ResultInfo?) = try await client.performRequest(request)
    }
}
