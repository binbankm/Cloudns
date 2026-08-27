import Foundation

/// Cloudflare Tunnels (Zero Trust) 领域服务抽象协议
protocol TunnelServiceProtocol: Sendable {
    func getTunnels(accountId: String) async throws -> [CFTunnel]
    func createTunnel(accountId: String, name: String) async throws -> CFTunnel
    func deleteTunnel(accountId: String, tunnelId: String) async throws
    func getTunnelConfigurations(accountId: String, tunnelId: String) async throws -> [TunnelIngressRule]
    func updateTunnelConfigurations(accountId: String, tunnelId: String, ingressRules: [TunnelIngressRule]) async throws
    func getTunnelToken(accountId: String, tunnelId: String) async throws -> String?
}

/// 统一的 Cloudflare Tunnels (Zero Trust) 领域服务
final class TunnelService: TunnelServiceProtocol {
    // MARK: - Lifecycle & Dependencies
    static let shared = TunnelService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    // MARK: - Cloudflare Tunnels API
    func getTunnels(accountId: String) async throws -> [CFTunnel] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/cfd_tunnel")
        let (tunnels, _): ([CFTunnel]?, ResultInfo?) = try await client.performRequest(request)
        return tunnels ?? []
    }
    
    func createTunnel(accountId: String, name: String) async throws -> CFTunnel {
        let payload: [String: Any] = ["name": name, "config_src": "cloudflare"]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/cfd_tunnel", method: "POST", body: data)
        let (tunnel, _): (CFTunnel?, ResultInfo?) = try await client.performRequest(request)
        guard let t = tunnel else { throw APIError.cloudflareError("Failed to create tunnel") }
        return t
    }
    
    func deleteTunnel(accountId: String, tunnelId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/cfd_tunnel/\(tunnelId)", method: "DELETE")
        struct DeleteRes: Codable { let id: String? }
        let (_, _): (DeleteRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func getTunnelConfigurations(accountId: String, tunnelId: String) async throws -> [TunnelIngressRule] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/cfd_tunnel/\(tunnelId)/configurations")
        struct TunnelConfigPayload: Codable {
            let config: TunnelConfigWrapper?
        }
        struct TunnelConfigWrapper: Codable {
            let ingress: [TunnelIngressRule]?
        }
        let (res, _): (TunnelConfigPayload?, ResultInfo?) = try await client.performRequest(request)
        return res?.config?.ingress ?? []
    }
    
    func updateTunnelConfigurations(accountId: String, tunnelId: String, ingressRules: [TunnelIngressRule]) async throws {
        struct ConfigBody: Codable {
            struct InnerConfig: Codable {
                let ingress: [TunnelIngressRule]
            }
            let config: InnerConfig
        }
        let body = ConfigBody(config: ConfigBody.InnerConfig(ingress: ingressRules))
        let data = try JSONEncoder().encode(body)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/cfd_tunnel/\(tunnelId)/configurations", method: "PUT", body: data)
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func getTunnelToken(accountId: String, tunnelId: String) async throws -> String? {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/cfd_tunnel/\(tunnelId)/token")
        let (token, _): (String?, ResultInfo?) = try await client.performRequest(request)
        return token
    }
}
