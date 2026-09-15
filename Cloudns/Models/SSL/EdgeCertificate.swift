import Foundation

struct CertificatePack: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let type: String
    let hosts: [String]
    let status: String
    let validationMethod: String?
    let primaryCertificate: String?
    let certificates: [PackCertificate]?

    enum CodingKeys: String, CodingKey {
        case id, type, hosts, status
        case validationMethod = "validation_method"
        case primaryCertificate = "primary_certificate"
        case certificates
    }
}

struct PackCertificate: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let hosts: [String]
    let issuer: String
    let signature: String
    let status: String
    let expiresOn: String

    enum CodingKeys: String, CodingKey {
        case id, hosts, issuer, signature, status
        case expiresOn = "expires_on"
    }
}

/// Unified model for display
struct EdgeCertificateModel: Identifiable, Equatable, Sendable {
    let id: String
    let type: String // "universal", "advanced", "custom"
    let hosts: [String]
    let issuer: String
    let status: String
    let expiresOn: String
    let signature: String
}

/// Cloudflare SSL Verification details for hostnames
struct SSLVerificationItem: Codable, Identifiable, Equatable, Sendable {
    var id: String {
        hostname
    }

    let hostname: String
    let certificateStatus: String?
    let verificationType: String?
    let verificationStatus: String?

    enum CodingKeys: String, CodingKey {
        case hostname
        case certificateStatus = "certificate_status"
        case verificationType = "verification_type"
        case verificationStatus = "verification_status"
    }
}
