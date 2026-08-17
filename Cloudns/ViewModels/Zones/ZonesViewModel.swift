import Foundation
import SwiftUI
import Combine

@MainActor
class ZonesViewModel: BaseLoadableViewModel {
    @Published var zones: [Zone] = []
    @Published var canLoadMore: Bool = false
    @Published var totalCount: Int = 0
    private var currentPage: Int = 1
    
    func filteredZones(query: String) -> [Zone] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return zones
        } else {
            return zones.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
        }
    }
    
    func fetchZones(isRefresh: Bool = true) async {
        if isRefresh {
            currentPage = 1
            await executeSWR(
                cacheKey: "cloudflare_zones_list",
                targetType: [Zone].self,
                onCached: { cachedZones in
                    self.zones = cachedZones
                    self.totalCount = cachedZones.count
                },
                fetcher: {
                    let (fetchedZones, resultInfo) = try await ZoneService.shared.getZones(page: 1)
                    if let info = resultInfo, info.page < info.totalPages {
                        self.canLoadMore = true
                        self.currentPage = 2
                    } else {
                        self.canLoadMore = false
                    }
                    self.totalCount = resultInfo?.totalCount ?? fetchedZones.count
                    return fetchedZones
                },
                onFresh: { latestZones in
                    self.zones = latestZones
                }
            )
        } else {
            if !canLoadMore { return }
            do {
                let (fetchedZones, resultInfo) = try await ZoneService.shared.getZones(page: currentPage)
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
            let accounts = try await CloudflareAPIClient.shared.getAccounts()
            guard let firstAccount = accounts.first else {
                addZoneError = "No Cloudflare account found."
                isAddingZone = false
                return nil
            }
            
            let zone = try await CloudflareAPIClient.shared.createZone(name: name, accountId: firstAccount.id)
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
            try await CloudflareAPIClient.shared.deleteZone(zoneId: zoneId)
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
}
