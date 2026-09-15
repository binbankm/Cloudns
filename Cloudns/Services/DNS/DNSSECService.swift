import Foundation

/// Protocol defining Cloudflare DNSSEC management domain service
protocol DNSSECServiceProtocol: Sendable {
    func getDNSSEC(zoneId: String) async throws -> DNSSEC
    func updateDNSSEC(zoneId: String, status: String) async throws -> DNSSEC
}

/// Concrete domain service for Cloudflare DNSSEC
final class DNSSECService: DNSSECServiceProtocol {
    static let shared = DNSSECService()

    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared

    private init() {}

    /// Fetches DNSSEC status and DS record details
    func getDNSSEC(zoneId: String) async throws -> DNSSEC {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/dnssec")
        let (dnssec, _): (DNSSEC?, ResultInfo?) = try await client.performRequest(request)
        guard let dnssec else {
            throw APIError.cloudflareError("DNSSEC details not found.")
        }
        return dnssec
    }

    /// Updates DNSSEC status (active / disabled)
    func updateDNSSEC(zoneId: String, status: String) async throws -> DNSSEC {
        let payload = ["status": status]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/dnssec", method: "PATCH", body: data)
        let (dnssec, _): (DNSSEC?, ResultInfo?) = try await client.performRequest(request)
        guard let dnssec else {
            throw APIError.cloudflareError("Failed to update DNSSEC status.")
        }
        return dnssec
    }
}
