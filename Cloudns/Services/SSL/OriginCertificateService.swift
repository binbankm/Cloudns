import Foundation

/// Protocol defining Cloudflare Origin CA & Client Certificates domain service
protocol OriginCertificateServiceProtocol: Sendable {
    func getOriginCertificates(zoneId: String?) async throws -> [OriginCACertificate]
    func createOriginCertificate(request certRequest: OriginCACertificateRequest) async throws -> OriginCACertificate
    func revokeOriginCertificate(certificateId: String) async throws
    func getClientCertificates(zoneId: String) async throws -> [ClientCertificate]
}

/// Concrete domain service for Cloudflare Origin CA and mTLS Client Certificates
final class OriginCertificateService: OriginCertificateServiceProtocol {
    static let shared = OriginCertificateService()

    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared

    private init() {}

    /// Fetches Origin CA certificates (GET /client/v4/certificates)
    func getOriginCertificates(zoneId: String? = nil) async throws -> [OriginCACertificate] {
        var queryItems: [URLQueryItem] = []
        if let zoneId, !zoneId.isEmpty {
            queryItems.append(URLQueryItem(name: "zone_id", value: zoneId))
        }
        let request = try factory.createAuthenticatedRequest(path: "certificates", queryItems: queryItems.isEmpty ? nil : queryItems)
        let (certs, _): ([OriginCACertificate]?, ResultInfo?) = try await client.performRequest(request)
        return certs ?? []
    }

    /// Creates an Origin CA certificate (POST /client/v4/certificates)
    func createOriginCertificate(request certRequest: OriginCACertificateRequest) async throws -> OriginCACertificate {
        let body = try JSONEncoder().encode(certRequest)
        let request = try factory.createAuthenticatedRequest(path: "certificates", method: "POST", body: body)
        let (cert, _): (OriginCACertificate?, ResultInfo?) = try await client.performRequest(request)
        guard let cert else {
            throw APIError.cloudflareError("Failed to generate Origin CA certificate.")
        }
        return cert
    }

    /// Revokes an Origin CA certificate (DELETE /client/v4/certificates/{certificate_id})
    func revokeOriginCertificate(certificateId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "certificates/\(certificateId)", method: "DELETE")
        _ = try await client.performDataRequest(request)
    }

    /// Fetches zone client certificates for mTLS (GET /client/v4/zones/{zone_id}/client_certificates)
    func getClientCertificates(zoneId: String) async throws -> [ClientCertificate] {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/client_certificates")
        let (certs, _): ([ClientCertificate]?, ResultInfo?) = try await client.performRequest(request)
        return certs ?? []
    }
}
