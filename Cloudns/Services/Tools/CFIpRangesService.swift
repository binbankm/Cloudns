import Foundation

/// Protocol defining Cloudflare official IP ranges service
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
        let (data, _): (CloudflareIPRanges?, ResultInfo?) = try await client.performRequest(request)
        return (data?.ipv4Cidrs ?? [], data?.ipv6Cidrs ?? [])
    }
}
