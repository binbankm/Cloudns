import Foundation

/// Protocol defining Cloudflare Dashboard and global aggregation service
protocol DashboardServiceProtocol: Sendable {
    func getFleetMetrics(zoneTags: [String]) async throws -> [FleetHourlyMetric]
    func getSparklines(zoneTags: [String]) async throws -> [String: ZoneSparklineCache]
}

/// Concrete domain service for Cloudflare Dashboard and global data aggregation
final class DashboardService: DashboardServiceProtocol {
    static let shared = DashboardService()
    
    private let analyticsService: AnalyticsServiceProtocol
    
    init(analyticsService: AnalyticsServiceProtocol = AnalyticsService.shared) {
        self.analyticsService = analyticsService
    }
    
    /// Fetches 24-hour hourly aggregated traffic trends across all active account domains
    func getFleetMetrics(zoneTags: [String]) async throws -> [FleetHourlyMetric] {
        try await analyticsService.getFleetAnalytics(zoneTags: zoneTags)
    }
    
    /// Fetches 24-hour sparkline data points for multiple domains
    func getSparklines(zoneTags: [String]) async throws -> [String: ZoneSparklineCache] {
        try await analyticsService.getBatchZonesSparklines(zoneTags: zoneTags)
    }
}
