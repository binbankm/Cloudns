import Foundation
import SwiftUI
import Combine

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var dataPoints: [AnalyticsDataPoint] = []
    @Published var mapDataPoints: [CountryDataPoint] = []
    @Published var isLoading: Bool = false
    @Published var hasFetchedData: Bool = false
    @Published var errorMessage: String? = nil
    
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
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await apiClient.fetchGraphQLAnalytics(zoneTag: zoneTag, days: days)
            if let zones = result.viewer.zones,
               let zone = zones.first {
                let groups = zone.httpRequests1dGroups ?? zone.httpRequests1hGroups ?? []
                let countryGroups = zone.trafficByCountry1d ?? zone.trafficByCountry1h ?? []
                self.dataPoints = groups
                self.mapDataPoints = countryGroups
                self.hasFetchedData = true
            } else {
                self.dataPoints = []
                self.mapDataPoints = []
                self.hasFetchedData = true
            }
        } catch APIError.cloudflareError(let message) {
            self.errorMessage = message
            self.hasFetchedData = true
        } catch APIError.decodingError(let error) {
            self.errorMessage = "Decoding Error: \(error)"
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to fetch analytics data: \(error.localizedDescription)"
            self.hasFetchedData = true
        }
        
        isLoading = false
    }
}
