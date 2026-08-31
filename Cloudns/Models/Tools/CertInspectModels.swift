import Foundation

// MARK: - SSL & TLS Certificate Diagnostic Models

public struct SSLCertDetails: Identifiable, Equatable, Sendable {
    public var id: String { commonName + (issuer ?? "") }
    public let commonName: String
    public let issuer: String?
    public let validityDaysRemaining: Int?
    public let protocolNegotiated: String?
    public let cipherSuite: String?
    public let chainCount: Int
    public let chainNames: [String]
    public let isCloudflareEdge: Bool
    public let validFrom: String?
    public let validUntil: String?
    public let sans: [String]
    public let signatureAlgorithm: String?
    public let keyTypeAndBits: String?
    public let isExpired: Bool
    
    public init(
        commonName: String,
        issuer: String? = nil,
        validityDaysRemaining: Int? = 90,
        protocolNegotiated: String? = "TLSv1.3",
        cipherSuite: String? = "TLS_AES_256_GCM_SHA384",
        chainCount: Int = 2,
        chainNames: [String] = [],
        isCloudflareEdge: Bool = true,
        validFrom: String? = nil,
        validUntil: String? = nil,
        sans: [String] = [],
        signatureAlgorithm: String? = "SHA-256 with RSA/ECDSA",
        keyTypeAndBits: String? = "ECDSA 256 bits (P-256)",
        isExpired: Bool = false
    ) {
        self.commonName = commonName
        self.issuer = issuer
        self.validityDaysRemaining = validityDaysRemaining
        self.protocolNegotiated = protocolNegotiated
        self.cipherSuite = cipherSuite
        self.chainCount = chainCount
        self.chainNames = chainNames.isEmpty ? [commonName, issuer ?? "Certificate Authority"] : chainNames
        self.isCloudflareEdge = isCloudflareEdge
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.sans = sans
        self.signatureAlgorithm = signatureAlgorithm
        self.keyTypeAndBits = keyTypeAndBits
        self.isExpired = isExpired
    }
}
