import Foundation

/// Protocol defining Cloudflare Custom SSL Certificates domain service
protocol CustomCertificateServiceProtocol: Sendable {
    func fetchCustomCertificates(zoneId: String) async throws -> [CustomCertificate]
    func uploadCustomCertificate(zoneId: String, certificate: String, privateKey: String, bundleMethod: String) async throws -> CustomCertificate
    func deleteCustomCertificate(zoneId: String, certificateId: String) async throws
}

/// Concrete domain service for Cloudflare Custom SSL Certificates
final class CustomCertificateService: CustomCertificateServiceProtocol {
    static let shared = CustomCertificateService()

    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared

    private init() {}

    /// Fetches all custom certificates uploaded for a zone
    func fetchCustomCertificates(zoneId: String) async throws -> [CustomCertificate] {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/custom_certificates")
        let (certs, _): ([CustomCertificate]?, ResultInfo?) = try await client.performRequest(request)
        return certs ?? []
    }

    /// Uploads a custom SSL certificate with private key and bundling method
    func uploadCustomCertificate(zoneId: String, certificate: String, privateKey: String, bundleMethod: String = "ubiquitous") async throws -> CustomCertificate {
        let uploadReq = CustomCertificateUploadRequest(certificate: certificate, privateKey: privateKey, bundleMethod: bundleMethod)
        let data = try JSONEncoder().encode(uploadReq)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/custom_certificates", method: "POST", body: data)
        let (cert, _): (CustomCertificate?, ResultInfo?) = try await client.performRequest(request)
        guard let c = cert else { throw APIError.cloudflareError("Failed to upload custom certificate") }
        return c
    }

    /// Deletes a custom SSL certificate from a zone
    func deleteCustomCertificate(zoneId: String, certificateId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/custom_certificates/\(certificateId)", method: "DELETE")
        let (_, _): (CloudflareIDResponse?, ResultInfo?) = try await client.performRequest(request)
    }
}
