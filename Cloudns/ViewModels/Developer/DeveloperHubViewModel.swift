import Foundation
import SwiftUI
import Combine

struct DeveloperHubSnapshot: Codable, Sendable {
    let workers: [WorkerScript]
    let pagesProjects: [PagesProject]
    let r2Buckets: [R2Bucket]
    let kvNamespaces: [KVNamespace]
    let d1Databases: [D1Database]
    let tunnels: [CFTunnel]
}

@MainActor
class DeveloperHubViewModel: BaseLoadableViewModel {
    private let zoneService: ZoneServiceProtocol
    private let workerService: WorkerServiceProtocol
    private let pagesService: PagesServiceProtocol
    private let r2Service: R2ServiceProtocol
    private let kvService: KVServiceProtocol
    private let d1Service: D1ServiceProtocol
    private let tunnelService: TunnelServiceProtocol
    
    @Published var accounts: [Account] = []
    @Published var selectedAccount: Account?
    
    @Published var workers: [WorkerScript] = []
    @Published var pagesProjects: [PagesProject] = []
    @Published var r2Buckets: [R2Bucket] = []
    @Published var kvNamespaces: [KVNamespace] = []
    @Published var d1Databases: [D1Database] = []
    @Published var tunnels: [CFTunnel] = []
    
    init(
        zoneService: ZoneServiceProtocol = ZoneService.shared,
        workerService: WorkerServiceProtocol = WorkerService.shared,
        pagesService: PagesServiceProtocol = PagesService.shared,
        r2Service: R2ServiceProtocol = R2Service.shared,
        kvService: KVServiceProtocol = KVService.shared,
        d1Service: D1ServiceProtocol = D1Service.shared,
        tunnelService: TunnelServiceProtocol = TunnelService.shared
    ) {
        self.zoneService = zoneService
        self.workerService = workerService
        self.pagesService = pagesService
        self.r2Service = r2Service
        self.kvService = kvService
        self.d1Service = d1Service
        self.tunnelService = tunnelService
        super.init()
    }
    
    var activeTunnelCount: Int {
        tunnels.filter { $0.isHealthy }.count
    }
    
    func fetchOverview(isRefresh: Bool = false) async {
        if !isRefresh && hasFetchedData && !isStale { return }
        
        let scopedKey = SWRCacheStore.accountScopedKey("developer_hub_overview_snapshot")
        
        // 1. [Stale] 0ms 尝试从缓存瞬间加载旧数据
        if !hasFetchedData, let cached = await SWRCacheStore.shared.get(forKey: scopedKey, as: DeveloperHubSnapshot.self) {
            self.workers = cached.workers
            self.pagesProjects = cached.pagesProjects
            self.r2Buckets = cached.r2Buckets
            self.kvNamespaces = cached.kvNamespaces
            self.d1Databases = cached.d1Databases
            self.tunnels = cached.tunnels
            self.hasFetchedData = true
        }
        
        // 2. 确保已解析出当前账户
        if selectedAccount == nil || accounts.isEmpty || isRefresh {
            if let fetchedAccounts = try? await zoneService.getAccounts(), !fetchedAccounts.isEmpty {
                self.accounts = fetchedAccounts
                let activeEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
                self.selectedAccount = fetchedAccounts.first(where: { $0.name == activeEmail || $0.id == activeEmail }) ?? fetchedAccounts.first
            }
        }
        
        guard let accountId = selectedAccount?.id, !accountId.isEmpty else {
            return
        }
        
        // 3. [Revalidate] 并发静默拉取开发者各项资源最新数据
        async let fetchWorkers = (try? await workerService.getWorkers(accountId: accountId)) ?? []
        async let fetchPages = (try? await pagesService.getPagesProjects(accountId: accountId)) ?? []
        async let fetchR2 = (try? await r2Service.getR2Buckets(accountId: accountId)) ?? []
        async let fetchKV = (try? await kvService.getKVNamespaces(accountId: accountId)) ?? []
        async let fetchD1 = (try? await d1Service.getD1Databases(accountId: accountId)) ?? []
        async let fetchTunnels = (try? await tunnelService.getTunnels(accountId: accountId)) ?? []
        
        let (w, p, r, k, d, t) = await (fetchWorkers, fetchPages, fetchR2, fetchKV, fetchD1, fetchTunnels)
        
        self.workers = w
        self.pagesProjects = p
        self.r2Buckets = r
        self.kvNamespaces = k
        self.d1Databases = d
        self.tunnels = t
        self.hasFetchedData = true
        self.lastFetchTime = Date()
        
        // 4. 持久化最新非空快照
        let snapshot = DeveloperHubSnapshot(
            workers: w,
            pagesProjects: p,
            r2Buckets: r,
            kvNamespaces: k,
            d1Databases: d,
            tunnels: t
        )
        await SWRCacheStore.shared.set(snapshot, forKey: scopedKey)
    }
}
