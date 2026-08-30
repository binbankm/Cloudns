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
    
}
