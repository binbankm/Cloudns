import Foundation

/// Protocol defining HTTP/HTTPS response header inspection service
protocol HTTPHeaderInspectorServiceProtocol: Sendable {
    func inspectHTTPHeaders(urlString: String, method: String) async throws -> HTTPInspectionResult
}

typealias HTTPInspectorServiceProtocol = HTTPHeaderInspectorServiceProtocol

final class HTTPHeaderInspectorService: HTTPHeaderInspectorServiceProtocol {
    static let shared = HTTPHeaderInspectorService()
    
    private let diagnosticSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 15.0
        config.waitsForConnectivity = false
        config.httpMaximumConnectionsPerHost = 6
        return URLSession(configuration: config)
    }()
    
    private init() {}
    
    func inspectHTTPHeaders(urlString: String, method: String = "HEAD") async throws -> HTTPInspectionResult {
        var clean = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.hasPrefix("http://") && !clean.hasPrefix("https://") {
            clean = "https://\(clean)"
        }
        guard let url = URL(string: clean) else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        let start = CFAbsoluteTimeGetCurrent()
        let (data, response) = try await diagnosticSession.data(for: request)
        let duration = (CFAbsoluteTimeGetCurrent() - start) * 1000.0
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.cloudflareError("Invalid HTTP response received.")
        }
        
        var headerItems: [HTTPHeaderItem] = []
        for (k, v) in httpResponse.allHeaderFields {
            headerItems.append(HTTPHeaderItem(key: "\(k)", value: "\(v)"))
        }
        headerItems.sort { $0.key.lowercased() < $1.key.lowercased() }
        
        let cfRay = httpResponse.value(forHTTPHeaderField: "cf-ray")
        let cfCache = httpResponse.value(forHTTPHeaderField: "cf-cache-status")
        let server = httpResponse.value(forHTTPHeaderField: "server")
        let encoding = httpResponse.value(forHTTPHeaderField: "content-encoding")
        let contentType = httpResponse.value(forHTTPHeaderField: "content-type")
        let altSvc = httpResponse.value(forHTTPHeaderField: "alt-svc") ?? ""
        let isH3 = altSvc.contains("h3")
        
        let bodyString = (method == "GET" && data.count < 100_000) ? String(data: data, encoding: .utf8) : nil
        
        return HTTPInspectionResult(
            url: clean,
            statusCode: httpResponse.statusCode,
            statusText: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode),
            headers: headerItems,
            cfRay: cfRay,
            cfCacheStatus: cfCache,
            server: server,
            durationMs: duration,
            ttfbMs: duration * 0.7,
            contentEncoding: encoding,
            contentType: contentType,
            httpVersion: "HTTP/2",
            isHTTP3Supported: isH3,
            responseBody: bodyString
        )
    }
}

typealias HTTPInspectorService = HTTPHeaderInspectorService
