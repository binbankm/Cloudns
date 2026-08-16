import Foundation

struct ActionParameters: Codable {
    // Cache Rules
    var cache: Bool?
    var edge_ttl: CacheEdgeTTL?
    var browser_ttl: CacheBrowserTTL?
    
    // Transform Rules
    var uri: URIRewrite?
    var headers: [String: HeaderTransform]?
    
    // Snippet Rules
    var snippet_name: String?
}

struct CacheEdgeTTL: Codable {
    var mode: String
    var default_ttl: Int?
    
    enum CodingKeys: String, CodingKey {
        case mode
        case default_ttl = "default"
    }
}

struct CacheBrowserTTL: Codable {
    var mode: String
    var default_ttl: Int?
    
    enum CodingKeys: String, CodingKey {
        case mode
        case default_ttl = "default"
    }
}

struct URIRewrite: Codable {
    var path: RewriteTarget?
    var query: RewriteTarget?
}

struct RewriteTarget: Codable {
    var value: String?
    var expression: String?
}

struct HeaderTransform: Codable {
    var operation: String
    var value: String?
    var expression: String?
}
