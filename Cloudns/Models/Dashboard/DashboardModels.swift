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
}
