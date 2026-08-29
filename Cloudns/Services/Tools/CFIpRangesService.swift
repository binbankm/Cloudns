import Foundation

/// Cloudflare 官方 IP 范围领域服务协议
protocol CFIpRangesServiceProtocol: Sendable {
    func getCloudflareIPs() async throws -> ([String], [String])
}

final class CFIpRangesService: CFIpRangesServiceProtocol {
    static let shared = CFIpRangesService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func getCloudflareIPs() async throws -> ([String], [String]) {
        let request = try factory.createAuthenticatedRequest(path: "ips")
        struct CFIPsResponse: Codable {
            let ipv4_cidrs: [String]?
            let ipv6_cidrs: [String]?
        }
        let (data, _): (CFIPsResponse?, ResultInfo?) = try await client.performRequest(request)
        return (data?.ipv4_cidrs ?? [], data?.ipv6_cidrs ?? [])
    }
}
