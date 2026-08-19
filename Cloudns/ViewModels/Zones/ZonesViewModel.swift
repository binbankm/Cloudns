import Foundation
import SwiftUI
import Combine

@MainActor
class ZonesViewModel: BaseLoadableViewModel {
    @Published var zones: [Zone] = []
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
                    self.syncFirstZoneToWidget(zones: latestZones)
                }
            )
        } else {
            // 分页加载下一页
            guard canLoadMore else { return }
            do {
                let (fetchedZones, resultInfo) = try await self.zoneService.getZones(page: currentPage, perPage: 50, name: nil, status: nil)
                self.zones.append(contentsOf: fetchedZones)
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
            // Remove locally
            if let index = zones.firstIndex(where: { $0.id == zoneId }) {
                zones.remove(at: index)
                totalCount -= 1
                // 同步刷新本地缓存
                await SWRCacheStore.shared.set(zones, forKey: SWRCacheStore.accountScopedKey("cloudflare_zones_list"))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isDeleting = false
    }
    
    private func syncFirstZoneToWidget(zones: [Zone]) {
        guard let first = zones.first else { return }
        let snap = ZoneWidgetSnapshot(
            id: first.id,
            name: first.name,
            status: first.status,
            plan: first.plan?.name ?? "Free",
            requests24h: 0,
            cachedRatio: 0.85,
            threats24h: 0,
            isProxied: true,
            isSSLEnabled: true,
            lastUpdated: Date()
        )
        WidgetDataStore.shared.saveZoneSnapshot(snap)
    }
}
