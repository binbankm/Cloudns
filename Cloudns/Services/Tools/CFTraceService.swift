import Foundation

/// Protocol defining Cloudflare /cdn-cgi/trace node diagnostics service
protocol CFTraceServiceProtocol: Sendable {
    func getCFTrace(host: String) async throws -> [HTTPHeaderItem]
}

final class CFTraceService: CFTraceServiceProtocol {
    static let shared = CFTraceService()
    
    private let diagnosticSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 15.0
        config.waitsForConnectivity = false
        config.httpMaximumConnectionsPerHost = 6
        return URLSession(configuration: config)
    }()
    
    private init() {}
    
    func getCFTrace(host: String = "www.cloudflare.com") async throws -> [HTTPHeaderItem] {
        let cleanHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        guard let url = URL(string: "https://\(cleanHost)/cdn-cgi/trace") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        let (data, response) = try await diagnosticSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
              let body = String(data: data, encoding: .utf8) else {
            throw APIError.cloudflareError("Failed to fetch /cdn-cgi/trace")
        }
        
        var items: [HTTPHeaderItem] = []
        let lines = body.components(separatedBy: "\n")
        for line in lines {
            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                let k = parts[0].trimmingCharacters(in: .whitespaces)
                let v = parts[1].trimmingCharacters(in: .whitespaces)
                if !k.isEmpty {
                    items.append(HTTPHeaderItem(key: k, value: v))
                }
            }
        }
        return items
    }
}
