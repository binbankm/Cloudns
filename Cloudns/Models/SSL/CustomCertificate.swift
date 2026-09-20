import Foundation

public struct GeoRestrictions: Codable, Equatable, Sendable {
    public let label: String

    public init(label: String) {
        self.label = label
    }
}

public struct CustomCertificate: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let hosts: [String]
    public let issuer: String?
    public let expires_on: String?
    public let status: String?
    public let signature: String?
    public let bundle_method: String?
    public let geo_restrictions: GeoRestrictions?
    public let uploaded_on: String?
    public let modified_on: String?

    public init(
        id: String,
        hosts: [String],
        issuer: String? = "Custom CA",
        expires_on: String? = nil,
        status: String? = "active",
        signature: String? = "Custom",
        bundle_method: String? = "ubiquitous",
        geo_restrictions: GeoRestrictions? = nil,
        uploaded_on: String? = nil,
        modified_on: String? = nil
    ) {
        self.id = id
        self.hosts = hosts
        self.issuer = issuer
        self.expires_on = expires_on
        self.status = status
        self.signature = signature
        self.bundle_method = bundle_method
        self.geo_restrictions = geo_restrictions
        self.uploaded_on = uploaded_on
        self.modified_on = modified_on
    }
}

public struct CustomCertificatesResponse: Codable, Sendable {
    public let success: Bool
    public let errors: [CloudflareError]?
    public let result: [CustomCertificate]?
}

public struct CustomCertificateUploadRequest: Codable, Sendable {
    public let certificate: String
    public let private_key: String
    public let bundle_method: String
    public let geo_restrictions: GeoRestrictions?

    public init(certificate: String, private_key: String, bundle_method: String = "ubiquitous", geo_restrictions: GeoRestrictions? = nil) {
        self.certificate = certificate
        self.private_key = private_key
        self.bundle_method = bundle_method
        self.geo_restrictions = geo_restrictions
    }
}

public struct CustomCertificateUpdateRequest: Codable, Sendable {
    public let certificate: String?
    public let private_key: String?
    public let bundle_method: String?
    public let geo_restrictions: GeoRestrictions?

    public init(certificate: String? = nil, private_key: String? = nil, bundle_method: String? = nil, geo_restrictions: GeoRestrictions? = nil) {
        self.certificate = certificate
        self.private_key = private_key
        self.bundle_method = bundle_method
        self.geo_restrictions = geo_restrictions
    }
}
