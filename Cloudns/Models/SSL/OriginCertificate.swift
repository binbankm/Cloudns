import Foundation

// MARK: - Origin CA & Client Certificate Models (Codable, Sendable, Equatable)

public struct OriginCACertificate: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let certificate: String
    public let hostnames: [String]
    public let expiresOn: String?
    public let requestType: String?
    public let requestedValidity: Int?
    public let csr: String?

    enum CodingKeys: String, CodingKey {
        case id, certificate, hostnames, csr
        case expiresOn = "expires_on"
        case requestType = "request_type"
        case requestedValidity = "requested_validity"
    }

    public init(
        id: String,
        certificate: String,
        hostnames: [String],
        expiresOn: String? = nil,
        requestType: String? = nil,
        requestedValidity: Int? = nil,
        csr: String? = nil
    ) {
        self.id = id
        self.certificate = certificate
        self.hostnames = hostnames
        self.expiresOn = expiresOn
        self.requestType = requestType
        self.requestedValidity = requestedValidity
        self.csr = csr
    }
}

public struct OriginCACertificateRequest: Codable, Equatable, Sendable {
    public let hostnames: [String]
    public let requestType: String
    public let requestedValidity: Int
    public let csr: String?

    enum CodingKeys: String, CodingKey {
        case hostnames, csr
        case requestType = "request_type"
        case requestedValidity = "requested_validity"
    }

    public init(hostnames: [String], requestType: String = "origin-rsa", requestedValidity: Int = 5475, csr: String? = nil) {
        self.hostnames = hostnames
        self.requestType = requestType
        self.requestedValidity = requestedValidity
        self.csr = csr
    }
}

public struct ClientCertificate: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let certificate: String?
    public let commonName: String?
    public let issuedOn: String?
    public let expiresOn: String?
    public let status: String?

    enum CodingKeys: String, CodingKey {
        case id, certificate, status
        case commonName = "common_name"
        case issuedOn = "issued_on"
        case expiresOn = "expires_on"
    }

    public init(
        id: String,
        certificate: String? = nil,
        commonName: String? = nil,
        issuedOn: String? = nil,
        expiresOn: String? = nil,
        status: String? = nil
    ) {
        self.id = id
        self.certificate = certificate
        self.commonName = commonName
        self.issuedOn = issuedOn
        self.expiresOn = expiresOn
        self.status = status
    }
}
