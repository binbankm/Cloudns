import Foundation

// MARK: - Cloudflare Official IP Ranges Models

public struct CloudflareIPRanges: Codable, Sendable {
    public let ipv4Cidrs: [String]
    public let ipv6Cidrs: [String]
    
    enum CodingKeys: String, CodingKey {
        case ipv4Cidrs = "ipv4_cidrs"
        case ipv6Cidrs = "ipv6_cidrs"
    }
    
    public init(ipv4Cidrs: [String] = [], ipv6Cidrs: [String] = []) {
        self.ipv4Cidrs = ipv4Cidrs
        self.ipv6Cidrs = ipv6Cidrs
    }
}
