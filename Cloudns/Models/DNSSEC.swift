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
}
