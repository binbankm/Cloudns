import Foundation

// MARK: - Dashboard Snapshot (SWR Offline Persistence)

public struct DashboardSnapshot: Codable, Sendable {
    public let zones: [Zone]
    public let workers: [WorkerScript]
    public let pages: [PagesProject]
    public let tunnels: [CFTunnel]
    public let kvCount: Int
    public let r2Count: Int
    public let d1Count: Int
    
    public init(
        zones: [Zone],
        workers: [WorkerScript],
        pages: [PagesProject],
        tunnels: [CFTunnel],
        kvCount: Int,
        r2Count: Int,
        d1Count: Int
    ) {
        self.zones = zones
        self.workers = workers
        self.pages = pages
        self.tunnels = tunnels
        self.kvCount = kvCount
        self.r2Count = r2Count
        self.d1Count = d1Count
    }
}

// MARK: - Dashboard Fleet Trend Chart Models

public enum DashboardChartMetric: String, CaseIterable, Identifiable, Sendable {
    case requests = "Requests"
    case bandwidth = "Bandwidth"
    case threats = "Threats"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .requests: return "Requests"
        case .bandwidth: return "Bandwidth"
        case .threats: return "Threats"
        }
    }
    
    public var icon: String {
        switch self {
        case .requests: return "chart.bar.fill"
        case .bandwidth: return "arrow.up.arrow.down"
        case .threats: return "shield.lefthalf.filled"
        }
    }
}

public struct FleetHourlyMetric: Identifiable, Codable, Equatable, Sendable {
    public var id: String { timeString }
    public let date: Date
    public let timeString: String
    public let requests: Double
    public let bytes: Double
    public let cachedRequests: Double
    public let threats: Double
    
    public init(
        date: Date,
        timeString: String,
        requests: Double,
        bytes: Double,
        cachedRequests: Double,
        threats: Double
    ) {
        self.date = date
        self.timeString = timeString
        self.requests = requests
        self.bytes = bytes
        self.cachedRequests = cachedRequests
        self.threats = threats
    }
    
    public static var placeholder24h: [FleetHourlyMetric] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<24).map { idx in
            let date = calendar.date(byAdding: .hour, value: -(23 - idx), to: now) ?? now
            let hourStr = DateFormatters.formatHour(date)
            let wave = sin(Double(idx) / 24.0 * .pi * 2.0) * 12000.0
            let baseReq = max(10000, 50000.0 + wave)
            let baseBytes = baseReq * 18000.0
            let baseCached = baseReq * 0.85
            let baseThreats = 150.0
            return FleetHourlyMetric(
                date: date,
                timeString: hourStr,
                requests: baseReq,
                bytes: baseBytes,
                cachedRequests: baseCached,
                threats: baseThreats
            )
        }
    }
}
