import Foundation

// MARK: - DNS Analytics Telemetry Models (Codable, Sendable, Equatable)

public struct DNSAnalyticsReport: Codable, Equatable, Sendable {
    public let totalQueries: Int
    public let responseCodes: [DNSResponseCodeMetric]
    public let queryTypes: [DNSQueryTypeMetric]

    public init(
        totalQueries: Int = 0,
        responseCodes: [DNSResponseCodeMetric] = [],
        queryTypes: [DNSQueryTypeMetric] = []
    ) {
        self.totalQueries = totalQueries
        self.responseCodes = responseCodes
        self.queryTypes = queryTypes
    }
}

public struct DNSResponseCodeMetric: Identifiable, Codable, Equatable, Sendable {
    public var id: String { responseCode }
    public let responseCode: String
    public let count: Int

    public init(responseCode: String, count: Int) {
        self.responseCode = responseCode
        self.count = count
    }
}

public struct DNSQueryTypeMetric: Identifiable, Codable, Equatable, Sendable {
    public var id: String { queryType }
    public let queryType: String
    public let count: Int

    public init(queryType: String, count: Int) {
        self.queryType = queryType
        self.count = count
    }
}
