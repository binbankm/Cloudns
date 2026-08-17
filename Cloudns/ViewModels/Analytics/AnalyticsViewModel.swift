import Foundation
import SwiftUI
import Combine

@MainActor
class AnalyticsViewModel: BaseLoadableViewModel {
    @Published var dataPoints: [AnalyticsDataPoint] = []
    @Published var mapDataPoints: [CountryDataPoint] = []
    
    let apiClient = CloudflareAPIClient.shared
    
    // Aggregated Metrics
    var totalRequests: Int {
        dataPoints.reduce(0) { $0 + $1.sum.requests }
    }
    
    var totalCachedRequests: Int {
        dataPoints.reduce(0) { $0 + $1.sum.cachedRequests }
    }
    
    var totalBandwidthBytes: Int {
        dataPoints.reduce(0) { $0 + $1.sum.bytes }
    }
    
    var totalCachedBandwidthBytes: Int {
        dataPoints.reduce(0) { $0 + $1.sum.cachedBytes }
    }
    
    var cachedRatio: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(totalCachedRequests) / Double(totalRequests)
    }
    
    func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .binary
        formatter.allowsNonnumericFormatting = false
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    func fetchAnalytics(zoneTag: String, days: Int) async {
        await executeLoadingTask {
            let result = try await self.apiClient.fetchGraphQLAnalytics(zoneTag: zoneTag, days: days)
            if let zones = result.viewer.zones, let zone = zones.first {
                let groups = zone.httpRequests1dGroups ?? zone.httpRequests1hGroups ?? []
                self.dataPoints = groups
                
                // Aggregate countryMap across all time buckets
                var countryAgg: [String: Int] = [:]
                for group in groups {
                    if let entries = group.sum.countryMap {
                        for entry in entries {
                            if let code = entry.clientCountryName, let reqs = entry.requests, reqs > 0 {
                                countryAgg[code, default: 0] += reqs
                            }
                        }
                    }
                }
                
                self.mapDataPoints = countryAgg.map { (code, count) in
                    CountryDataPoint(
                        dimensions: CountryDimensions(clientCountryName: code),
                        count: count,
                        sum: CountrySum(requests: count)
                    )
                }.sorted { ($0.count ?? 0) > ($1.count ?? 0) }
            } else {
                self.dataPoints = []
                self.mapDataPoints = []
            }
        }
    }
}
