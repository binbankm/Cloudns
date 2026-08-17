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
    var snippet: SnippetRef?
    
    // Redirect Rules
    var from_value: FromValue?
    
    struct SnippetRef: Codable {
        var name: String
        public init(name: String) { self.name = name }
    }
    
    struct FromValue: Codable {
        var status_code: Int?
        var target_url: TargetUrl?
        var preserve_query_string: Bool?
        
        public init(status_code: Int? = nil, target_url: TargetUrl? = nil, preserve_query_string: Bool? = nil) {
            self.status_code = status_code
            self.target_url = target_url
            self.preserve_query_string = preserve_query_string
        }
    }
    
    struct TargetUrl: Codable {
        var value: String?
        var expression: String?
        
        public init(value: String? = nil, expression: String? = nil) {
            self.value = value
            self.expression = expression
        }
    }
    
    public init(
        cache: Bool? = nil,
        edge_ttl: CacheEdgeTTL? = nil,
        browser_ttl: CacheBrowserTTL? = nil,
        uri: URIRewrite? = nil,
        headers: [String: HeaderTransform]? = nil,
        snippet_name: String? = nil,
        snippet: SnippetRef? = nil,
        from_value: FromValue? = nil
    ) {
        self.cache = cache
        self.edge_ttl = edge_ttl
        self.browser_ttl = browser_ttl
        self.uri = uri
        self.headers = headers
        self.snippet_name = snippet_name
        self.snippet = snippet
        self.from_value = from_value
    }
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
