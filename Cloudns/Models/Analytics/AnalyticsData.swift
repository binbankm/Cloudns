import Foundation

struct GraphQLResponse<T: Codable & Sendable>: Codable, Sendable {
    let data: T?
    let errors: [GraphQLError]?
}

struct GraphQLError: Codable, Sendable {
    let message: String?
}

struct AnalyticsViewerData: Codable, Sendable {
    let viewer: AnalyticsViewer
}

struct AnalyticsViewer: Codable, Sendable {
    let zones: [AnalyticsZone]?
}

struct AnalyticsZone: Codable, Sendable {
    let zoneTag: String?
    let httpRequests1dGroups: [AnalyticsDataPoint]?
    let httpRequests1hGroups: [AnalyticsDataPoint]?
    let trafficByCountry1d: [CountryDataPoint]?
    let trafficByCountry1h: [CountryDataPoint]?
}

struct CountryDataPoint: Codable, Identifiable, Equatable, Sendable {
    var id: String { dimensions.clientCountryName ?? UUID().uuidString }
    let dimensions: CountryDimensions
    let count: Int?
    let sum: CountrySum?
    
    var requestsCount: Int {
        count ?? sum?.requests ?? 0
    }
}

struct CountrySum: Codable, Equatable, Sendable {
    let requests: Int?
}

struct CountryDimensions: Codable, Equatable, Sendable {
    let clientCountryName: String?
}

public struct CountryMapEntry: Codable, Equatable, Sendable {
    public let clientCountryName: String?
    public let requests: Int?
    public let threats: Int?
    public let bytes: Int?
}

public struct AnalyticsDataPoint: Codable, Identifiable, Equatable, Sendable {
    public var id: String { dimensions.datetime ?? dimensions.date ?? UUID().uuidString }
    public let dimensions: AnalyticsDimensions
    public let sum: AnalyticsSum
}

public struct AnalyticsDimensions: Codable, Equatable, Sendable {
    public let date: String? // e.g., "2023-09-02"
    public let datetime: String? // e.g., "2023-09-02T15:00:00Z"
}

public struct AnalyticsSum: Codable, Equatable, Sendable {
    public let requests: Int
    public let bytes: Int
    public let cachedRequests: Int
    public let cachedBytes: Int
    public let threats: Int?
    public let countryMap: [CountryMapEntry]?
    
    enum CodingKeys: String, CodingKey {
        case requests
        case bytes
        case cachedRequests
        case cachedBytes
        case threats
        case countryMap
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.requests = try container.decodeIfPresent(Int.self, forKey: .requests) ?? 0
        self.bytes = try container.decodeIfPresent(Int.self, forKey: .bytes) ?? 0
        self.cachedRequests = try container.decodeIfPresent(Int.self, forKey: .cachedRequests) ?? 0
        self.cachedBytes = try container.decodeIfPresent(Int.self, forKey: .cachedBytes) ?? 0
        self.threats = try container.decodeIfPresent(Int.self, forKey: .threats)
        self.countryMap = try container.decodeIfPresent([CountryMapEntry].self, forKey: .countryMap)
    }
    
    public init(requests: Int, bytes: Int, cachedRequests: Int, cachedBytes: Int, threats: Int? = nil, countryMap: [CountryMapEntry]? = nil) {
        self.requests = requests
        self.bytes = bytes
        self.cachedRequests = cachedRequests
        self.cachedBytes = cachedBytes
        self.threats = threats
        self.countryMap = countryMap
    }
}

// MARK: - Workers & Pages GraphQL Analytics Models

public struct WorkerAnalyticsItem: Codable, Identifiable, Equatable, Sendable {
    public var id: String {
        let dim = dimensions.datetimeHour ?? dimensions.datetime ?? dimensions.date ?? UUID().uuidString
        let status = dimensions.status ?? ""
        return "\(dim)_\(status)"
    }
    public let dimensions: WorkerAnalyticsDimensions
    public let sum: WorkerAnalyticsSum?
    public let quantiles: WorkerAnalyticsQuantiles?
    
    public struct WorkerAnalyticsDimensions: Codable, Equatable, Sendable {
        public let datetimeHour: String?
        public let datetime: String?
        public let date: String?
        public let status: String?
        public let scriptName: String?
        public let environment: String?
    }
    
    public struct WorkerAnalyticsSum: Codable, Equatable, Sendable {
        public let requests: Int?
        public let errors: Int?
        public let subrequests: Int?
    }
    
    public struct WorkerAnalyticsQuantiles: Codable, Equatable, Sendable {
        public let cpuTimeP50: Double?
        public let cpuTimeP99: Double?
    }
}

public struct WorkerAnalyticsSummaryItem: Codable, Equatable, Sendable {
    public let sum: WorkerAnalyticsItem.WorkerAnalyticsSum?
    public let quantiles: WorkerAnalyticsItem.WorkerAnalyticsQuantiles?
}

public struct WorkerAnalyticsAccountItem: Codable, Sendable {
    public let summary: [WorkerAnalyticsSummaryItem]?
    public let series: [WorkerAnalyticsItem]?
    public let byStatus: [WorkerAnalyticsItem]?
    public let workersInvocationsAdaptive: [WorkerAnalyticsItem]?
    public let pagesFunctionsInvocationsAdaptiveGroups: [WorkerAnalyticsItem]?
}

public struct WorkerAnalyticsViewer: Codable, Sendable {
    public let accounts: [WorkerAnalyticsAccountItem]?
}

public struct WorkerAnalyticsViewerData: Codable, Sendable {
    public let viewer: WorkerAnalyticsViewer
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
