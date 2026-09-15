import Foundation

// MARK: - DNSSEC Details (Cloudflare DNSSEC v4)

public struct DNSSEC: Codable, Equatable, Sendable {
    public var status: String
    public var ds: String?
    public var digest: String?
    public var digestType: String?
    public var digestAlgorithm: String?
    public var algorithm: String?
    public var publicKey: String?
    public var keyTag: Int?
    public var flags: Int?

    /// Backward-compatible computed accessors
    public var digest_type: String? {
        digestType
    }

    public var digest_algorithm: String? {
        digestAlgorithm
    }

    public var public_key: String? {
        publicKey
    }

    public var key_tag: Int? {
        keyTag
    }

    enum CodingKeys: String, CodingKey {
        case status, ds, digest, algorithm, flags
        case digestType = "digest_type"
        case digestAlgorithm = "digest_algorithm"
        case publicKey = "public_key"
        case keyTag = "key_tag"
    }

    public init(
        status: String,
        ds: String? = nil,
        digest: String? = nil,
        digestType: String? = nil,
        digestAlgorithm: String? = nil,
        algorithm: String? = nil,
        publicKey: String? = nil,
        keyTag: Int? = nil,
        flags: Int? = nil
    ) {
        self.status = status
        self.ds = ds
        self.digest = digest
        self.digestType = digestType
        self.digestAlgorithm = digestAlgorithm
        self.algorithm = algorithm
        self.publicKey = publicKey
        self.keyTag = keyTag
        self.flags = flags
    }
}
