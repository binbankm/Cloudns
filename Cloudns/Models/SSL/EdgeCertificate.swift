import Foundation

struct CertificatePack: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let type: String
    let hosts: [String]
    let status: String
    let validation_method: String?
    let primary_certificate: String?
    let certificates: [PackCertificate]?
}

struct PackCertificate: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let hosts: [String]
    let issuer: String
    let signature: String
    let status: String
    let expires_on: String
}

struct CFAPIError: Codable, Equatable, Sendable {
    let code: Int?
    let message: String?
}

struct CertificatePacksResponse: Codable, Sendable {
    let success: Bool
    let errors: [CFAPIError]?
    let messages: [String]?
    let result: [CertificatePack]?
}

// Unified model for display
struct EdgeCertificateModel: Identifiable, Equatable, Sendable {
    let id: String
    let type: String // "universal", "advanced", "custom"
    let hosts: [String]
    let issuer: String
    let status: String
    let expiresOn: String
    let signature: String
}
