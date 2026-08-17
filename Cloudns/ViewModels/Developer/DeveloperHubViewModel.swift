import Foundation
import SwiftUI
import Combine

@MainActor
class DeveloperHubViewModel: BaseLoadableViewModel {
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var accounts: [Account] = []
    @Published var selectedAccount: Account?
    
    @Published var workers: [WorkerScript] = []
    @Published var pagesProjects: [PagesProject] = []
    @Published var r2Buckets: [R2Bucket] = []
    @Published var kvNamespaces: [KVNamespace] = []
    @Published var d1Databases: [D1Database] = []
    @Published var tunnels: [CFTunnel] = []
    
    override init() {
        super.init()
        self.hasFetchedData = true
    }
    
    var activeTunnelCount: Int {
        tunnels.filter { $0.isHealthy }.count
    }
    
    func fetchOverview(isRefresh: Bool = false) async {
        if selectedAccount == nil || accounts.isEmpty || isRefresh {
            if let fetchedAccounts = try? await apiClient.getAccounts(), !fetchedAccounts.isEmpty {
                self.accounts = fetchedAccounts
                let activeEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
                self.selectedAccount = fetchedAccounts.first(where: { $0.name == activeEmail || $0.id == activeEmail }) ?? fetchedAccounts.first
            }
        }
        
        guard let accountId = selectedAccount?.id, !accountId.isEmpty else {
            return
        }
        
        // 并发静默拉取开发者各项资源徽标计数（不阻塞任何 UI）
        async let fetchWorkers = (try? await apiClient.getWorkers(accountId: accountId)) ?? []
        async let fetchPages = (try? await apiClient.getPagesProjects(accountId: accountId)) ?? []
        async let fetchR2 = (try? await apiClient.getR2Buckets(accountId: accountId)) ?? []
        async let fetchKV = (try? await apiClient.getKVNamespaces(accountId: accountId)) ?? []
        async let fetchD1 = (try? await apiClient.getD1Databases(accountId: accountId)) ?? []
        async let fetchTunnels = (try? await apiClient.getTunnels(accountId: accountId)) ?? []
        
        let (w, p, r, k, d, t) = await (fetchWorkers, fetchPages, fetchR2, fetchKV, fetchD1, fetchTunnels)
        
        self.workers = w
        self.pagesProjects = p
        self.r2Buckets = r
        self.kvNamespaces = k
        self.d1Databases = d
        self.tunnels = t
    }
}
