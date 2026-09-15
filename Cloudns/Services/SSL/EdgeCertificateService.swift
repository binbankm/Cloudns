import Foundation

/// Protocol defining Cloudflare Edge Certificates (Universal SSL & Certificate Packs) domain service
protocol EdgeCertificateServiceProtocol: Sendable {
    func getCertificates(zoneId: String) async throws -> [CertificatePack]
    func getUniversalSSLSetting(zoneId: String) async throws -> Bool
    func updateUniversalSSL(zoneId: String, enabled: Bool) async throws
    func deleteCertificatePack(zoneId: String, packId: String) async throws
    func getSSLVerification(zoneId: String) async throws -> [SSLVerificationItem]
}

/// Concrete domain service for Cloudflare Edge Certificates
final class EdgeCertificateService: EdgeCertificateServiceProtocol {
    static let shared = EdgeCertificateService()

    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared

    private init() {}

    /// Fetches all certificate packs (Universal and Advanced) for a zone
    func getCertificates(zoneId: String) async throws -> [CertificatePack] {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/ssl/certificate_packs")
        let (certs, _): ([CertificatePack]?, ResultInfo?) = try await client.performRequest(request)
        return certs ?? []
    }

    /// Fetches Universal SSL status for a zone
    func getUniversalSSLSetting(zoneId: String) async throws -> Bool {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/ssl/universal/settings")
        struct UniversalSSLSettingResult: Codable {
            let enabled: Bool?
        }
        let (setting, _): (UniversalSSLSettingResult?, ResultInfo?) = try await client.performRequest(request)
        guard let enabled = setting?.enabled else {
            throw APIError.decodingError("Universal SSL settings unavailable in response")
        }
        return enabled
    }

    /// Toggles Universal SSL setting for a zone
    func updateUniversalSSL(zoneId: String, enabled: Bool) async throws {
        let payload = ["enabled": enabled]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/ssl/universal/settings", method: "PATCH", body: data)
        struct UniversalSSLSettingResult: Codable {
            let enabled: Bool?
        }
        let (_, _): (UniversalSSLSettingResult?, ResultInfo?) = try await client.performRequest(request)
    }

    /// Deletes an advanced certificate pack
    func deleteCertificatePack(zoneId: String, packId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/ssl/certificate_packs/\(packId)", method: "DELETE")
        let (_, _): (CloudflareIDResponse?, ResultInfo?) = try await client.performRequest(request)
    }

    /// Fetches SSL verification details for pending hostnames
    func getSSLVerification(zoneId: String) async throws -> [SSLVerificationItem] {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/ssl/verification")
        let (items, _): ([SSLVerificationItem]?, ResultInfo?) = try await client.performRequest(request)
        return items ?? []
    }
}
