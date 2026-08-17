import Foundation

struct DNSSECResponse: Codable {
    let result: DNSSEC
    let success: Bool
}

struct DNSSEC: Codable {
    var status: String
    var ds: String?
    var digest: String?
    var digest_type: String?
    var digest_algorithm: String?
    var algorithm: String?
    var public_key: String?
    var key_tag: Int?
    var flags: Int?
    
    static let placeholder = DNSSEC(
        status: "active",
        ds: "example.com. 3600 IN DS 2371 13 2 4004D79...8F",
        digest: "4004D79...8F",
        digest_type: "2",
        digest_algorithm: "SHA-256",
        algorithm: "13 (ECDSA Curve P-256 with SHA-256)",
        public_key: "mdsswUf...==",
        key_tag: 2371,
        flags: 257
    )
}
