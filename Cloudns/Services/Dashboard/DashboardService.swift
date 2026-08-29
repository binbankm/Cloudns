import Foundation

/// Cloudflare 控制台与全局数据聚合领域服务协议
protocol DashboardServiceProtocol: Sendable {
    func getFleetMetrics(zoneTags: [String]) async throws -> [FleetHourlyMetric]
    func getSparklines(zoneTags: [String]) async throws -> [String: ZoneSparklineCache]
}

/// 统一的 Cloudflare 控制台与全局数据聚合领域服务
final class DashboardService: DashboardServiceProtocol {
    static let shared = DashboardService()
    
    private let analyticsService: AnalyticsServiceProtocol
    
    init(analyticsService: AnalyticsServiceProtocol = AnalyticsService.shared) {
        self.analyticsService = analyticsService
    }
    
    /// 获取全账号所有活跃域名的 24 小时逐小时聚合趋势
    func getFleetMetrics(zoneTags: [String]) async throws -> [FleetHourlyMetric] {
        try await analyticsService.getFleetAnalytics(zoneTags: zoneTags)
    }
    
    /// 获取多个域名的 24 小时微图 Sparkline 点位
    func getSparklines(zoneTags: [String]) async throws -> [String: ZoneSparklineCache] {
        try await analyticsService.getBatchZonesSparklines(zoneTags: zoneTags)
    }
}
