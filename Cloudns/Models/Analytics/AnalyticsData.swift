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
    let count: Int
}

struct CountryDimensions: Codable {
    let clientCountryName: String?
}

struct AnalyticsDataPoint: Codable, Identifiable {
    var id: String { dimensions.datetime ?? dimensions.date ?? UUID().uuidString }
    let dimensions: AnalyticsDimensions
    let sum: AnalyticsSum
}

struct AnalyticsDimensions: Codable {
    let date: String? // e.g., "2023-09-02"
    let datetime: String? // e.g., "2023-09-02T15:00:00Z"
}

struct AnalyticsSum: Codable {
    let requests: Int
    let bytes: Int
    let cachedRequests: Int
    let cachedBytes: Int
}

// MARK: - Workers & Pages GraphQL Analytics Models

public struct WorkerAnalyticsItem: Codable, Identifiable, Equatable {
    public var id: String { "\(dimensions.datetime ?? "")_\(dimensions.status ?? "")" }
    public let dimensions: WorkerAnalyticsDimensions
    public let sum: WorkerAnalyticsSum?
    public let quantiles: WorkerAnalyticsQuantiles?
    
    public struct WorkerAnalyticsDimensions: Codable, Equatable {
        public let datetime: String?
        public let status: String?
        public let scriptName: String?
    }
    
    public struct WorkerAnalyticsSum: Codable, Equatable {
        public let requests: Int?
        public let errors: Int?
        public let subrequests: Int?
    }
    
    public struct WorkerAnalyticsQuantiles: Codable, Equatable {
        public let cpuTimeP50: Double?
        public let cpuTimeP99: Double?
        public let durationMsP50: Double?
        public let durationMsP99: Double?
    }
}

public struct WorkerAnalyticsAccountItem: Codable {
    public let workersInvocationsAdaptive: [WorkerAnalyticsItem]?
}

public struct WorkerAnalyticsViewer: Codable {
    public let accounts: [WorkerAnalyticsAccountItem]?
}

public struct WorkerAnalyticsViewerData: Codable {
    public let viewer: WorkerAnalyticsViewer
}
