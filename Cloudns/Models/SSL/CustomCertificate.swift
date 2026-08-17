import Foundation

struct CustomCertificate: Codable, Identifiable {
    let id: String
    let hosts: [String]
    let issuer: String
    let expires_on: String
    let status: String
    let signature: String
}

struct CustomCertificatesResponse: Codable {
    let success: Bool
    let errors: [CloudflareError]?
    let result: [CustomCertificate]?
}

struct CustomCertificateUploadRequest: Codable {
    let certificate: String
    let private_key: String
    let bundle_method: String
}
