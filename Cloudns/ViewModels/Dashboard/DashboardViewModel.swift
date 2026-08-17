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
        if !isRefresh && hasFetchedData && !isStale { return }
        
        let scopedKey = SWRCacheStore.accountScopedKey("dashboard_overview_snapshot")
        
        // 1. [Stale] 0ms 尝试从缓存预加载
        if !hasFetchedData, let cached = await SWRCacheStore.shared.get(forKey: scopedKey, as: DashboardSnapshot.self) {
            self.zones = cached.zones
            self.workers = cached.workers
            self.pages = cached.pages
            self.tunnels = cached.tunnels
            self.kvCount = cached.kvCount
            self.r2Count = cached.r2Count
            self.d1Count = cached.d1Count
            self.hasFetchedData = true
        }
        
        // 2. [Revalidate / Refresh] 统一执行前台/下拉拉取
        await executeLoadingTask(clearError: false) {
            // A. 获取账户列表
            let fetchedAccounts = (try? await self.apiClient.getAccounts()) ?? []
            if !fetchedAccounts.isEmpty {
                self.accounts = fetchedAccounts
                let activeEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
                let currentAcc = fetchedAccounts.first(where: { $0.name == activeEmail || $0.id == activeEmail }) ?? fetchedAccounts.first
                self.selectedAccount = currentAcc
            }
            
            // B. 获取域名列表
            if let fetchedZones = try? await self.apiClient.getZones().0 {
                self.zones = fetchedZones
            }
            
            // C. 获取开发者全套资源
            if let accountId = self.selectedAccount?.id, !accountId.isEmpty {
                async let fetchW = try? self.apiClient.getWorkers(accountId: accountId)
                async let fetchP = try? self.apiClient.getPagesProjects(accountId: accountId)
                async let fetchT = try? self.apiClient.getTunnels(accountId: accountId)
                async let fetchK = try? self.apiClient.getKVNamespaces(accountId: accountId)
                async let fetchR = try? self.apiClient.getR2Buckets(accountId: accountId)
                async let fetchD = try? self.apiClient.getD1Databases(accountId: accountId)
                
                let (w, p, t, k, r, d) = await (fetchW, fetchP, fetchT, fetchK, fetchR, fetchD)
                
                if let w { self.workers = w }
                if let p { self.pages = p }
                if let t { self.tunnels = t }
                if let k { self.kvCount = k.count }
                if let r { self.r2Count = r.count }
                if let d { self.d1Count = d.count }
            }
            
            // D. 持久化最新非空快照，杜绝缓存毒化
            if !self.zones.isEmpty || !self.workers.isEmpty || !self.pages.isEmpty || self.selectedAccount != nil {
                let snapshot = DashboardSnapshot(
                    zones: self.zones,
                    workers: self.workers,
                    pages: self.pages,
                    tunnels: self.tunnels,
                    kvCount: self.kvCount,
                    r2Count: self.r2Count,
                    d1Count: self.d1Count
                )
                await SWRCacheStore.shared.set(snapshot, forKey: scopedKey)
            }
        }
    }
}
