import Foundation

// MARK: - Cloudflare /cdn-cgi/trace Diagnostic Models

public struct HTTPHeaderItem: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let key: String
    public let value: String
    
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
    
    public static let tracePlaceholders: [HTTPHeaderItem] = [
        HTTPHeaderItem(key: "colo", value: "SFO"),
        HTTPHeaderItem(key: "ip", value: "198.51.100.42"),
        HTTPHeaderItem(key: "loc", value: "US"),
        HTTPHeaderItem(key: "warp", value: "plus"),
        HTTPHeaderItem(key: "gateway", value: "off"),
        HTTPHeaderItem(key: "kex", value: "X25519")
    ]
}
