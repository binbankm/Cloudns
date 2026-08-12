import Foundation

struct DNSSECResponse: Codable {
    let result: DNSSEC
    let success: Bool
}

struct DNSSEC: Codable {
    var status: String
}
