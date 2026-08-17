import Foundation

struct GraphQLResponse<T: Codable>: Codable {
    let data: T?
    let errors: [GraphQLError]?
}

struct GraphQLError: Codable {
    let message: String
}

struct AnalyticsViewerData: Codable {
    let viewer: AnalyticsViewer
}

struct AnalyticsViewer: Codable {
    let zones: [AnalyticsZone]?
}

struct AnalyticsZone: Codable {
    let httpRequests1dGroups: [AnalyticsDataPoint]?
    let httpRequests1hGroups: [AnalyticsDataPoint]?
    let trafficByCountry1d: [CountryDataPoint]?
    let trafficByCountry1h: [CountryDataPoint]?
}

struct CountryDataPoint: Codable, Identifiable {
    var id: String { dimensions.clientCountryName ?? UUID().uuidString }
    let dimensions: CountryDimensions
    let count: Int?
    let sum: CountrySum?
    
    var requestsCount: Int {
        count ?? sum?.requests ?? 0
    }
}

struct CountrySum: Codable {
    let requests: Int?
}

struct CountryDimensions: Codable {
    let clientCountryName: String?
}

public struct CountryMapEntry: Codable, Equatable {
    public let clientCountryName: String?
    public let requests: Int?
    public let threats: Int?
    public let bytes: Int?
}

public struct AnalyticsDataPoint: Codable, Identifiable {
    public var id: String { dimensions.datetime ?? dimensions.date ?? UUID().uuidString }
    public let dimensions: AnalyticsDimensions
    public let sum: AnalyticsSum
}

public struct AnalyticsDimensions: Codable {
    public let date: String? // e.g., "2023-09-02"
    public let datetime: String? // e.g., "2023-09-02T15:00:00Z"
}

public struct AnalyticsSum: Codable {
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

public struct WorkerAnalyticsItem: Codable, Identifiable, Equatable {
    public var id: String {
        let dim = dimensions.datetimeHour ?? dimensions.datetime ?? dimensions.date ?? UUID().uuidString
        let status = dimensions.status ?? ""
        return "\(dim)_\(status)"
    }
    public let dimensions: WorkerAnalyticsDimensions
    public let sum: WorkerAnalyticsSum?
    public let quantiles: WorkerAnalyticsQuantiles?
    
    public struct WorkerAnalyticsDimensions: Codable, Equatable {
        public let datetimeHour: String?
        public let datetime: String?
        public let date: String?
        public let status: String?
        public let scriptName: String?
        public let environment: String?
    }
    
    public struct WorkerAnalyticsSum: Codable, Equatable {
        public let requests: Int?
        public let errors: Int?
        public let subrequests: Int?
    }
    
    public struct WorkerAnalyticsQuantiles: Codable, Equatable {
        public let cpuTimeP50: Double?
        public let cpuTimeP99: Double?
    }
}

public struct WorkerAnalyticsSummaryItem: Codable, Equatable {
    public let sum: WorkerAnalyticsItem.WorkerAnalyticsSum?
    public let quantiles: WorkerAnalyticsItem.WorkerAnalyticsQuantiles?
}

public struct WorkerAnalyticsAccountItem: Codable {
    public let summary: [WorkerAnalyticsSummaryItem]?
    public let series: [WorkerAnalyticsItem]?
    public let byStatus: [WorkerAnalyticsItem]?
    public let workersInvocationsAdaptive: [WorkerAnalyticsItem]?
    public let pagesFunctionsInvocationsAdaptiveGroups: [WorkerAnalyticsItem]?
}

public struct WorkerAnalyticsViewer: Codable {
    public let accounts: [WorkerAnalyticsAccountItem]?
}

public struct WorkerAnalyticsViewerData: Codable {
    public let viewer: WorkerAnalyticsViewer
}
