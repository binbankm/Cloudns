import Foundation

/// Anycast 边缘延迟与抖动测速服务协议
protocol EdgeLatencyServiceProtocol: Sendable {
    func performEdgeLatencyTest(host: String, rounds: Int) async throws -> EdgeLatencyResult
}

final class EdgeLatencyService: EdgeLatencyServiceProtocol {
    static let shared = EdgeLatencyService()
    
    private let diagnosticSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 15.0
        config.waitsForConnectivity = false
        config.httpMaximumConnectionsPerHost = 6
        return URLSession(configuration: config)
    }()
    
    private init() {}
    
    func performEdgeLatencyTest(host: String, rounds: Int = 4) async throws -> EdgeLatencyResult {
        let cleanHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        guard let url = URL(string: "https://\(cleanHost)/cdn-cgi/trace") ?? URL(string: "https://\(cleanHost)") else {
            throw APIError.invalidURL
        }
        
        var pings: [EdgeLatencyPing] = []
        var serverHeader = "unknown"
        var isCF = false
        
        for idx in 1...rounds {
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            
            let start = CFAbsoluteTimeGetCurrent()
            do {
                let (_, response) = try await diagnosticSession.data(for: request)
                let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000.0
                if let http = response as? HTTPURLResponse {
                    serverHeader = http.value(forHTTPHeaderField: "server") ?? "unknown"
                    let cfRay = http.value(forHTTPHeaderField: "cf-ray")
                    isCF = serverHeader.lowercased().contains("cloudflare") || cfRay != nil
                    pings.append(EdgeLatencyPing(id: idx, latencyMs: elapsed, httpStatus: http.statusCode, isSuccess: true))
                }
            } catch {
                pings.append(EdgeLatencyPing(id: idx, latencyMs: 0, httpStatus: 0, isSuccess: false))
            }
            
            if idx < rounds {
                try? await Task.sleep(nanoseconds: 120_000_000)
            }
        }
        
        let successfulPings = pings.filter { $0.isSuccess }
        guard !successfulPings.isEmpty else {
            throw APIError.cloudflareError("All latency pings timed out.")
        }
        
        let latencies = successfulPings.map { $0.latencyMs }
        let minMs = latencies.min() ?? 0
        let maxMs = latencies.max() ?? 0
        let avgMs = latencies.reduce(0, +) / Double(latencies.count)
        let lossPercent = Double(rounds - successfulPings.count) / Double(rounds) * 100.0
        
        var jitterSum = 0.0
        for i in 0..<(latencies.count - 1) {
            jitterSum += abs(latencies[i] - latencies[i + 1])
        }
        let jitterMs = latencies.count > 1 ? jitterSum / Double(latencies.count - 1) : 0.0
        
        return EdgeLatencyResult(
            host: cleanHost,
            pings: pings,
            minMs: minMs,
            maxMs: maxMs,
            avgMs: avgMs,
            jitterMs: jitterMs,
            packetLossPercent: lossPercent,
            httpProtocol: "HTTP/2 (Anycast)",
            serverHeader: serverHeader,
            isCloudflareEdge: isCF
        )
    }
}
