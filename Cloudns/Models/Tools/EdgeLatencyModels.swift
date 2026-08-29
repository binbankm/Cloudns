import Foundation

// MARK: - Edge Latency & Jitter Models

public struct EdgeLatencyPing: Identifiable, Equatable, Sendable {
    public let id: Int
    public let latencyMs: Double
    public let httpStatus: Int
    public let isSuccess: Bool
    
    public init(id: Int, latencyMs: Double, httpStatus: Int, isSuccess: Bool) {
        self.id = id
        self.latencyMs = latencyMs
        self.httpStatus = httpStatus
        self.isSuccess = isSuccess
    }
}

public struct EdgeLatencyResult: Equatable, Sendable {
    public let host: String
    public let pings: [EdgeLatencyPing]
    public let minMs: Double
    public let maxMs: Double
    public let avgMs: Double
    public let jitterMs: Double
    public let packetLossPercent: Double
    public let httpProtocol: String
    public let serverHeader: String
    public let isCloudflareEdge: Bool
    
    public init(
        host: String,
        pings: [EdgeLatencyPing],
        minMs: Double,
        maxMs: Double,
        avgMs: Double,
        jitterMs: Double,
        packetLossPercent: Double,
        httpProtocol: String = "HTTP/2",
        serverHeader: String = "cloudflare",
        isCloudflareEdge: Bool = true
    ) {
        self.host = host
        self.pings = pings
        self.minMs = minMs
        self.maxMs = maxMs
        self.avgMs = avgMs
        self.jitterMs = jitterMs
        self.packetLossPercent = packetLossPercent
        self.httpProtocol = httpProtocol
        self.serverHeader = serverHeader
        self.isCloudflareEdge = isCloudflareEdge
    }
    
    public static let placeholder = EdgeLatencyResult(
        host: "example.com",
        pings: [
            EdgeLatencyPing(id: 1, latencyMs: 24.1, httpStatus: 200, isSuccess: true),
            EdgeLatencyPing(id: 2, latencyMs: 25.3, httpStatus: 200, isSuccess: true),
            EdgeLatencyPing(id: 3, latencyMs: 23.8, httpStatus: 200, isSuccess: true)
        ],
        minMs: 23.8,
        maxMs: 25.3,
        avgMs: 24.4,
        jitterMs: 1.5,
        packetLossPercent: 0.0,
        httpProtocol: "HTTP/2",
        serverHeader: "cloudflare",
        isCloudflareEdge: true
    )
}
