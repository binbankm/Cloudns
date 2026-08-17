import Foundation
import Combine
import SwiftUI

public struct DashboardSnapshot: Codable {
    public let zones: [Zone]
    public let workers: [WorkerScript]
    public let pages: [PagesProject]
    public let tunnels: [CFTunnel]
    public let kvCount: Int
    public let r2Count: Int
    public let d1Count: Int
}

@MainActor
final class DashboardViewModel: BaseLoadableViewModel {
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var accounts: [Account] = []
    @Published var selectedAccount: Account?
    
    @Published var zones: [Zone] = []
    @Published var workers: [WorkerScript] = []
    @Published var pages: [PagesProject] = []
    @Published var tunnels: [CFTunnel] = []
    
    @Published var kvCount: Int = 0
    @Published var r2Count: Int = 0
    @Published var d1Count: Int = 0
    
    var activeZonesCount: Int {
        zones.filter { $0.status.lowercased() == "active" }.count
    }
    
    var healthyTunnelsCount: Int {
        tunnels.filter { $0.isHealthy }.count
    }
    
    var totalStorageCount: Int {
        kvCount + r2Count + d1Count
    }
    
    var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<18: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    func fetchDashboard(isRefresh: Bool = false) async {
        if !isRefresh && hasFetchedData { return }
        
        await executeSWR(
            cacheKey: "dashboard_overview_snapshot",
            targetType: DashboardSnapshot.self,
            onCached: { snapshot in
                self.zones = snapshot.zones
                self.workers = snapshot.workers
                self.pages = snapshot.pages
                self.tunnels = snapshot.tunnels
                self.kvCount = snapshot.kvCount
                self.r2Count = snapshot.r2Count
                self.d1Count = snapshot.d1Count
            },
            fetcher: {
                // 1. Fetch accounts
                let fetchedAccounts = try await self.apiClient.getAccounts()
                self.accounts = fetchedAccounts
                
                let activeEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
                let currentAcc = fetchedAccounts.first(where: { $0.name == activeEmail || $0.id == activeEmail }) ?? fetchedAccounts.first
                self.selectedAccount = currentAcc
                
                // 2. Fully concurrent pipeline for zones and all developer resources
                async let fetchZones = (try? await self.apiClient.getZones())?.0 ?? []
                
                if let accountId = currentAcc?.id, !accountId.isEmpty {
                    async let fetchW = (try? await self.apiClient.getWorkers(accountId: accountId)) ?? []
                    async let fetchP = (try? await self.apiClient.getPagesProjects(accountId: accountId)) ?? []
                    async let fetchT = (try? await self.apiClient.getTunnels(accountId: accountId)) ?? []
                    async let fetchK = (try? await self.apiClient.getKVNamespaces(accountId: accountId)) ?? []
                    async let fetchR = (try? await self.apiClient.getR2Buckets(accountId: accountId)) ?? []
                    async let fetchD = (try? await self.apiClient.getD1Databases(accountId: accountId)) ?? []
                    
                    let (z, w, p, t, k, r, d) = await (fetchZones, fetchW, fetchP, fetchT, fetchK, fetchR, fetchD)
                    return DashboardSnapshot(
                        zones: z,
                        workers: w,
                        pages: p,
                        tunnels: t,
                        kvCount: k.count,
                        r2Count: r.count,
                        d1Count: d.count
                    )
                } else {
                    let z = await fetchZones
                    return DashboardSnapshot(
                        zones: z,
                        workers: [],
                        pages: [],
                        tunnels: [],
                        kvCount: 0,
                        r2Count: 0,
                        d1Count: 0
                    )
                }
            },
            onFresh: { snapshot in
                self.zones = snapshot.zones
                self.workers = snapshot.workers
                self.pages = snapshot.pages
                self.tunnels = snapshot.tunnels
                self.kvCount = snapshot.kvCount
                self.r2Count = snapshot.r2Count
                self.d1Count = snapshot.d1Count
            }
        )
    }
}
