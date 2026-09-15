import Foundation

/// Protocol defining Cloudflare authoritative DNS query analytics service
protocol DNSAnalyticsServiceProtocol: Sendable {
    func getDNSAnalytics(zoneTag: String, days: Int) async throws -> DNSAnalyticsReport
}

extension DNSAnalyticsServiceProtocol {
    func getDNSAnalytics(zoneTag: String, days: Int = 1) async throws -> DNSAnalyticsReport {
        try await getDNSAnalytics(zoneTag: zoneTag, days: days)
    }
}

/// Concrete domain service for Cloudflare DNS analytics
final class DNSAnalyticsService: DNSAnalyticsServiceProtocol {
    static let shared = DNSAnalyticsService()

    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared

    private init() {}

    /// Fetches authoritative DNS query analytics via GraphQL dnsAnalyticsAdaptiveGroups
    func getDNSAnalytics(zoneTag: String, days: Int = 1) async throws -> DNSAnalyticsReport {
        let pastDate: Date = if days == 1 {
            Calendar.current.date(byAdding: .hour, value: -24, to: Date()) ?? Date()
        } else {
            Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        }
        let startDateString = DateFormatters.formatISO8601(pastDate)
        let endDateString = DateFormatters.formatISO8601(Date())

        let query = """
        query {
          viewer {
            zones(filter: { zoneTag: "\(zoneTag)" }) {
              dnsAnalyticsAdaptiveGroups(
                limit: 1000,
                filter: {
                  datetime_geq: "\(startDateString)",
                  datetime_leq: "\(endDateString)"
                }
              ) {
                count
                dimensions {
                  responseCode
                  queryType
                }
              }
            }
          }
        }
        """

        let payload: [String: Any] = ["query": query]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "graphql", method: "POST", body: data)
        let rawData = try await client.performDataRequest(request)

        guard let json = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any],
              let dataObj = json["data"] as? [String: Any],
              let viewerObj = dataObj["viewer"] as? [String: Any],
              let zonesArray = viewerObj["zones"] as? [[String: Any]],
              let firstZone = zonesArray.first,
              let groups = firstZone["dnsAnalyticsAdaptiveGroups"] as? [[String: Any]]
        else {
            return DNSAnalyticsReport()
        }

        var totalQueries = 0
        var responseCodesMap: [String: Int] = [:]
        var queryTypesMap: [String: Int] = [:]

        for group in groups {
            let count = (group["count"] as? NSNumber)?.intValue ?? 0
            totalQueries += count

            if let dims = group["dimensions"] as? [String: Any] {
                if let rcode = dims["responseCode"] as? String, !rcode.isEmpty {
                    responseCodesMap[rcode, default: 0] += count
                }
                if let qtype = dims["queryType"] as? String, !qtype.isEmpty {
                    queryTypesMap[qtype, default: 0] += count
                }
            }
        }

        let sortedCodes = responseCodesMap.map { DNSResponseCodeMetric(responseCode: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        let sortedTypes = queryTypesMap.map { DNSQueryTypeMetric(queryType: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }

        return DNSAnalyticsReport(
            totalQueries: totalQueries,
            responseCodes: sortedCodes,
            queryTypes: sortedTypes
        )
    }
}
