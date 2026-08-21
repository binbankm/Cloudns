import Foundation
import SwiftUI
import Combine

nonisolated struct ZoneAnalyticsSnapshot: Codable, Sendable {
    let dataPoints: [AnalyticsDataPoint]
    let mapDataPoints: [CountryDataPoint]
    let loadedDays: Int
}

@MainActor
class AnalyticsViewModel: BaseLoadableViewModel {
    @Published var dataPoints: [AnalyticsDataPoint] = []
    @Published var mapDataPoints: [CountryDataPoint] = []
    @Published var loadedDays: Int = 30
    
    private let analyticsService: AnalyticsServiceProtocol
    
    init(analyticsService: AnalyticsServiceProtocol = AnalyticsService.shared) {
        self.analyticsService = analyticsService
        super.init()
    }
    
    func resetState() {
        self.dataPoints = []
        self.mapDataPoints = []
        self.resetLoadingState()
    }
    
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
    
    private func cacheKey(zoneTag: String, days: Int) -> String {
        "zone_analytics_\(zoneTag)_\(days)"
    }
    
    func fetchAnalytics(zoneTag: String, days: Int, isRefresh: Bool = false) async {
        let scopedKey = SWRCacheStore.accountScopedKey(cacheKey(zoneTag: zoneTag, days: days))
        
        // 1. [Stale] 0ms 尝试从缓存恢复
        if !hasFetchedData, let cached = await SWRCacheStore.shared.get(forKey: scopedKey, as: ZoneAnalyticsSnapshot.self) {
            await MainActor.run {
                self.dataPoints = cached.dataPoints
                self.mapDataPoints = cached.mapDataPoints
                self.loadedDays = cached.loadedDays
                self.hasFetchedData = true
            }
        }
        
        // 2. [Revalidate] 执行网络请求
        await executeLoadingTask(clearError: true) {
            let result = try await self.analyticsService.fetchGraphQLAnalytics(zoneTag: zoneTag, days: days)
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
                
                self.loadedDays = days
                
                // 写入缓存快照
                let snapshot = ZoneAnalyticsSnapshot(
                    dataPoints: self.dataPoints,
                    mapDataPoints: self.mapDataPoints,
                    loadedDays: days
                )
                await SWRCacheStore.shared.set(snapshot, forKey: scopedKey)
                self.syncAnalyticsToWidget(zoneTag: zoneTag)
            }
        }
    }
    
    private func syncAnalyticsToWidget(zoneTag: String) {
        Task {
            let current = WidgetDataStore.shared.loadZoneSnapshot()
            var domainName = current.name
            var status = current.status
            var plan = current.plan
            var isProxied = current.isProxied
            
            if current.id != zoneTag || domainName == "example.com" || domainName == "Active Zone" {
                let cacheKey = SWRCacheStore.accountScopedKey("cloudflare_zones_list")
                if let cachedZones = await SWRCacheStore.shared.get(forKey: cacheKey, as: [Zone].self),
                   let matched = cachedZones.first(where: { $0.id == zoneTag }) {
                    domainName = matched.name
                    status = matched.status
                    plan = matched.plan?.name ?? plan
                    isProxied = !matched.paused
                }
            }
            
            let snap = ZoneWidgetSnapshot(
                id: zoneTag,
                name: domainName,
                status: status,
                plan: plan,
                requests24h: self.totalRequests,
                cachedRatio: self.cachedRatio,
                threats24h: current.threats24h,
                isProxied: isProxied,
                isSSLEnabled: true,
                lastUpdated: Date()
            )
            WidgetDataStore.shared.saveZoneSnapshot(snap)
        }
    }
}
