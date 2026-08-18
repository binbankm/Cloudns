import Foundation

struct CustomCertificate: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let hosts: [String]
    let issuer: String?
    let expires_on: String?
    let status: String?
    let signature: String?
    
    init(id: String, hosts: [String], issuer: String? = "Custom CA", expires_on: String? = nil, status: String? = "active", signature: String? = "Custom") {
        self.id = id
        self.hosts = hosts
        self.issuer = issuer
        self.expires_on = expires_on
        self.status = status
        self.signature = signature
    }
}

struct CustomCertificatesResponse: Codable, Sendable {
    let success: Bool
    let errors: [CloudflareError]?
    let result: [CustomCertificate]?
}

struct CustomCertificateUploadRequest: Codable, Sendable {
    let certificate: String
    let private_key: String
    let bundle_method: String
}
