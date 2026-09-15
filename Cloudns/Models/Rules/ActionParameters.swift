import Foundation

struct ActionParameters: Codable, Equatable, Sendable {
    // Cache Rules
    var cache: Bool?
    var edgeTTL: CacheEdgeTTL?
    var browserTTL: CacheBrowserTTL?

    // Transform Rules
    var uri: URIRewrite?
    var headers: [String: HeaderTransform]?

    // Snippet Rules
    var snippetName: String?
    var snippet: SnippetRef?

    /// Redirect Rules
    var fromValue: FromValue?

    var edge_ttl: CacheEdgeTTL? {
        get { edgeTTL }
        set { edgeTTL = newValue }
    }

    var browser_ttl: CacheBrowserTTL? {
        get { browserTTL }
        set { browserTTL = newValue }
    }

    var snippet_name: String? {
        get { snippetName }
        set { snippetName = newValue }
    }

    var from_value: FromValue? {
        get { fromValue }
        set { fromValue = newValue }
    }

    enum CodingKeys: String, CodingKey {
        case cache
        case edgeTTL = "edge_ttl"
        case browserTTL = "browser_ttl"
        case uri, headers
        case snippetName = "snippet_name"
        case snippet
        case fromValue = "from_value"
    }

    struct SnippetRef: Codable, Equatable, Sendable {
        var name: String
    }

    struct FromValue: Codable, Equatable, Sendable {
        var statusCode: Int?
        var targetUrl: TargetUrl?
        var preserveQueryString: Bool?

        var status_code: Int? {
            get { statusCode }
            set { statusCode = newValue }
        }

        var target_url: TargetUrl? {
            get { targetUrl }
            set { targetUrl = newValue }
        }

        var preserve_query_string: Bool? {
            get { preserveQueryString }
            set { preserveQueryString = newValue }
        }

        enum CodingKeys: String, CodingKey {
            case statusCode = "status_code"
            case targetUrl = "target_url"
            case preserveQueryString = "preserve_query_string"
        }

        init(statusCode: Int? = nil, targetUrl: TargetUrl? = nil, preserveQueryString: Bool? = nil) {
            self.statusCode = statusCode
            self.targetUrl = targetUrl
            self.preserveQueryString = preserveQueryString
        }

        init(status_code: Int? = nil, target_url: TargetUrl? = nil, preserve_query_string: Bool? = nil) {
            statusCode = status_code
            targetUrl = target_url
            preserveQueryString = preserve_query_string
        }
    }

    struct TargetUrl: Codable, Equatable, Sendable {
        var value: String?
        var expression: String?

        init(value: String? = nil, expression: String? = nil) {
            self.value = value
            self.expression = expression
        }
    }

    init(
        cache: Bool? = nil,
        edgeTTL: CacheEdgeTTL? = nil,
        browserTTL: CacheBrowserTTL? = nil,
        uri: URIRewrite? = nil,
        headers: [String: HeaderTransform]? = nil,
        snippetName: String? = nil,
        snippet: SnippetRef? = nil,
        fromValue: FromValue? = nil
    ) {
        self.cache = cache
        self.edgeTTL = edgeTTL
        self.browserTTL = browserTTL
        self.uri = uri
        self.headers = headers
        self.snippetName = snippetName
        self.snippet = snippet
        self.fromValue = fromValue
    }
}

struct CacheEdgeTTL: Codable, Equatable, Sendable {
    var mode: String
    var defaultTTL: Int?

    var default_ttl: Int? {
        get { defaultTTL }
        set { defaultTTL = newValue }
    }

    enum CodingKeys: String, CodingKey {
        case mode
        case defaultTTL = "default"
    }

    init(mode: String, defaultTTL: Int? = nil) {
        self.mode = mode
        self.defaultTTL = defaultTTL
    }
}

struct CacheBrowserTTL: Codable, Equatable, Sendable {
    var mode: String
    var defaultTTL: Int?

    var default_ttl: Int? {
        get { defaultTTL }
        set { defaultTTL = newValue }
    }

    enum CodingKeys: String, CodingKey {
        case mode
        case defaultTTL = "default"
    }

    init(mode: String, defaultTTL: Int? = nil) {
        self.mode = mode
        self.defaultTTL = defaultTTL
    }
}

struct URIRewrite: Codable, Equatable, Sendable {
    var path: RewriteTarget?
    var query: RewriteTarget?
}

struct RewriteTarget: Codable, Equatable, Sendable {
    var value: String?
    var expression: String?
}

struct HeaderTransform: Codable, Equatable, Sendable {
    var operation: String
    var value: String?
    var expression: String?
}
