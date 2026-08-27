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
    
    static var dummyData: [EdgeCertificateModel] {
        return [
            EdgeCertificateModel(id: "dummy1", type: "universal", hosts: ["example.com", "*.example.com"], issuer: "Google Trust Services", status: "active", expiresOn: "2025-01-01T00:00:00Z", signature: "SHA256WithRSA"),
            EdgeCertificateModel(id: "dummy2", type: "custom", hosts: ["api.example.com"], issuer: "Let's Encrypt", status: "active", expiresOn: "2024-10-01T00:00:00Z", signature: "ECDSAWithSHA256")
        ]
    }
}
