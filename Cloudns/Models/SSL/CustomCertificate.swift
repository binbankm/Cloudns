import Foundation

struct CustomCertificate: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let hosts: [String]
    let issuer: String?
    let expiresOn: String?
    let status: String?
    let signature: String?

    var expires_on: String? { expiresOn }

    enum CodingKeys: String, CodingKey {
        case id, hosts, issuer, status, signature
        case expiresOn = "expires_on"
    }

    init(id: String, hosts: [String], issuer: String? = "Custom CA", expiresOn: String? = nil, status: String? = "active", signature: String? = "Custom") {
        self.id = id
        self.hosts = hosts
        self.issuer = issuer
        self.expiresOn = expiresOn
        self.status = status
        self.signature = signature
    }
}

struct CustomCertificateUploadRequest: Codable, Sendable {
    let certificate: String
    let privateKey: String
    let bundleMethod: String

    enum CodingKeys: String, CodingKey {
        case certificate
        case privateKey = "private_key"
        case bundleMethod = "bundle_method"
    }

    init(certificate: String, privateKey: String, bundleMethod: String = "ubiquitous") {
        self.certificate = certificate
        self.privateKey = privateKey
        self.bundleMethod = bundleMethod
    }
}
