import Foundation
import SwiftUI
import Combine

@MainActor
class ZonesViewModel: BaseLoadableViewModel {
    @Published var zones: [Zone] = []
    @Published var sparklines: [String: ZoneSparklineCache] = [:]
    @Published var canLoadMore: Bool = false
    @Published var totalCount: Int = 0
    private var currentPage: Int = 1
    
    private let zoneService: ZoneServiceProtocol
    
    init(zoneService: ZoneServiceProtocol = ZoneService.shared) {
        self.zoneService = zoneService
        super.init()
    }
    
    func filteredZones(query: String) -> [Zone] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return zones
        } else {
            return zones.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
        }
    }
    
    func resetState() {
        self.zones = []
        self.sparklines = [:]
        self.totalCount = 0
        self.canLoadMore = false
        self.currentPage = 1
        self.resetLoadingState()
    }
    
    func fetchZones(isRefresh: Bool = false) async {
        if !isRefresh && hasFetchedData && !isStale {
            return
        }
        
        if isRefresh || !hasFetchedData {
            currentPage = 1
            await executeSWR(
                cacheKey: "cloudflare_zones_list",
                targetType: [Zone].self,
                onCached: { cachedZones in
                    self.zones = cachedZones
                    self.totalCount = cachedZones.count
                    self.fetchBatchSparklines(for: cachedZones)
                    self.syncFirstZoneToWidget(zones: cachedZones)
                },
                fetcher: { [zoneService] in
                    let (fetchedZones, _) = try await zoneService.getZones(page: 1, perPage: 50, name: nil, status: nil)
                    return fetchedZones
                },
                onFresh: { latestZones in
                    self.zones = latestZones
                    self.totalCount = latestZones.count
                    self.canLoadMore = latestZones.count >= 50
                    self.currentPage = latestZones.count >= 50 ? 2 : 1
                    self.fetchBatchSparklines(for: latestZones)
                    self.syncFirstZoneToWidget(zones: latestZones)
                }
            )
        } else {
            // 分页加载下一页
            guard canLoadMore else { return }
            do {
                let (fetchedZones, resultInfo) = try await self.zoneService.getZones(page: currentPage, perPage: 50, name: nil, status: nil)
                self.zones.append(contentsOf: fetchedZones)
                self.fetchBatchSparklines(for: fetchedZones)
                if let info = resultInfo, info.page < info.totalPages {
                    canLoadMore = true
                    currentPage += 1
                } else {
                    canLoadMore = false
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    /// 一次性批量拉取当前列表中所有活跃 Zone 的 24h 流量走势微图（单次 GraphQL 网络请求）
    public func fetchBatchSparklines(for zones: [Zone]) {
        let activeZoneIds = zones.filter { $0.status.lowercased() == "active" }.map { $0.id }
        guard !activeZoneIds.isEmpty else { return }
        
        Task { [weak self] in
            guard let self = self else { return }
            // 1. 优先读取已有的 SWR 本地缓存，极速呈现
            for id in activeZoneIds {
                if let cached = await SWRCacheStore.shared.get(forKey: "zone_sparkline_\(id)", as: ZoneSparklineCache.self) {
                    await MainActor.run {
                        self.sparklines[id] = cached
                    }
                }
            }
            
            // 2. 单次聚合请求拉取全部域名的最新 24 小时点位
            if let batchMap = try? await AnalyticsService.shared.getBatchZonesSparklines(zoneTags: activeZoneIds) {
                await MainActor.run {
                    for (id, cache) in batchMap {
                        self.sparklines[id] = cache
                    }
                }
                for (id, cache) in batchMap {
                    await SWRCacheStore.shared.setMemoryOnly(cache, forKey: "zone_sparkline_\(id)")
                }
            }
        }
    }
    
    @Published var isAddingZone: Bool = false
    @Published var addZoneError: String?
    
    func addZone(name: String) async -> Zone? {
        isAddingZone = true
        addZoneError = nil
        do {
            let accounts = try await zoneService.getAccounts()
            guard let firstAccount = accounts.first else {
                addZoneError = "No Cloudflare account found."
                isAddingZone = false
                return nil
            }
            
            let zone = try await zoneService.createZone(name: name, accountId: firstAccount.id, jumpStart: false)
            NotificationCenter.default.post(name: .zoneCreated, object: nil, userInfo: ["zone": zone])
            await fetchZones(isRefresh: true)
            isAddingZone = false
            return zone
        } catch {
            addZoneError = error.localizedDescription
            isAddingZone = false
            return nil
        }
    }
    
    @Published var isDeleting: Bool = false
    
    func deleteZone(zoneId: String) async {
        isDeleting = true
        errorMessage = nil
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.warning)
        do {
            _ = try await zoneService.deleteZone(zoneId: zoneId)
            RecentZonesManager.shared.removeZone(zoneId: zoneId)
            await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("zone_details_\(zoneId)"))
            await SWRCacheStore.shared.remove(forKey: "zone_sparkline_\(zoneId)")
            
            // Remove locally
            if let index = zones.firstIndex(where: { $0.id == zoneId }) {
                zones.remove(at: index)
                totalCount = max(0, totalCount - 1)
                // 同步刷新本地缓存
                await SWRCacheStore.shared.set(zones, forKey: SWRCacheStore.accountScopedKey("cloudflare_zones_list"))
            }
            NotificationCenter.default.post(name: .zoneDeleted, object: nil, userInfo: ["zoneId": zoneId])
        } catch {
            errorMessage = error.localizedDescription
        }
        isDeleting = false
    }
    
    private func syncFirstZoneToWidget(zones: [Zone]) {
        let topZoneId = RecentZonesManager.shared.recentZoneIds.first
        let targetZone = zones.first(where: { $0.id == topZoneId }) ?? zones.first
        guard let chosen = targetZone else { return }
        WidgetDataStore.shared.syncZoneWithAnalytics(zone: chosen)
    }
}
