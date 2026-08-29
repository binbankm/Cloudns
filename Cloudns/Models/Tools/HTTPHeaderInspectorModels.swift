import Foundation

// MARK: - HTTP & Cache Inspection Models

public struct HTTPInspectionResult: Equatable, Sendable {
    public let url: String
    public let statusCode: Int
    public let statusText: String
    public let headers: [HTTPHeaderItem]
    public let cfRay: String?
    public let cfCacheStatus: String?
    public let server: String?
    public let durationMs: Double
    public let ttfbMs: Double
    public let contentEncoding: String?
    public let contentType: String?
    public let httpVersion: String
    public let isHTTP3Supported: Bool
    public let responseBody: String?
    
    public var responseHeaders: [String: String] {
        headers.reduce(into: [String: String]()) { $0[$1.key] = $1.value }
    }
    
    public init(
        url: String,
        statusCode: Int,
        statusText: String,
        headers: [HTTPHeaderItem],
        cfRay: String? = nil,
        cfCacheStatus: String? = nil,
        server: String? = nil,
        durationMs: Double,
        ttfbMs: Double = 0,
        contentEncoding: String? = nil,
        contentType: String? = nil,
        httpVersion: String = "HTTP/2",
        isHTTP3Supported: Bool = false,
        responseBody: String? = nil
    ) {
        self.url = url
        self.statusCode = statusCode
        self.statusText = statusText
        self.headers = headers
        self.cfRay = cfRay
        self.cfCacheStatus = cfCacheStatus
        self.server = server
        self.durationMs = durationMs
        self.ttfbMs = ttfbMs > 0 ? ttfbMs : durationMs * 0.75
        self.contentEncoding = contentEncoding
        self.contentType = contentType
        self.httpVersion = httpVersion
        self.isHTTP3Supported = isHTTP3Supported
        self.responseBody = responseBody
    }
    
    public static let placeholder = HTTPInspectionResult(
        url: "https://example.com",
        statusCode: 200,
        statusText: "OK",
        headers: [
            HTTPHeaderItem(key: "content-type", value: "text/html; charset=UTF-8"),
            HTTPHeaderItem(key: "server", value: "cloudflare"),
            HTTPHeaderItem(key: "cf-cache-status", value: "HIT"),
            HTTPHeaderItem(key: "cf-ray", value: "89a12bc34de56789-SJC")
        ],
        cfRay: "89a12bc34de56789-SJC",
        cfCacheStatus: "HIT",
        server: "cloudflare",
        durationMs: 42.5,
        ttfbMs: 31.2,
        contentEncoding: "br",
        contentType: "text/html; charset=UTF-8",
        httpVersion: "HTTP/2",
        isHTTP3Supported: true
    )
}
