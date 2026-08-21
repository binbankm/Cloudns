import Foundation
import Combine
import SwiftUI

nonisolated struct DashboardSnapshot: Codable, Sendable {
    let zones: [Zone]
    let workers: [WorkerScript]
    let pages: [PagesProject]
    let tunnels: [CFTunnel]
    let kvCount: Int
    let r2Count: Int
    let d1Count: Int
}

@MainActor
final class DashboardViewModel: BaseLoadableViewModel {
    private let zoneService: ZoneServiceProtocol
    private let workerService: WorkerServiceProtocol
    private let pagesService: PagesServiceProtocol
    private let tunnelService: TunnelServiceProtocol
    private let kvService: KVServiceProtocol
    private let r2Service: R2ServiceProtocol
    private let d1Service: D1ServiceProtocol
    
    @Published var accounts: [Account] = []
    @Published var selectedAccount: Account?
    
    @Published var zones: [Zone] = []
    @Published var workers: [WorkerScript] = []
    @Published var pages: [PagesProject] = []
    @Published var tunnels: [CFTunnel] = []
    
    @Published var kvCount: Int = 0
    @Published var r2Count: Int = 0
    @Published var d1Count: Int = 0
    
    @Published var sparklines: [String: ZoneSparklineCache] = [:]
    
    @Published var recentZones: [Zone] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        zoneService: ZoneServiceProtocol = ZoneService.shared,
        workerService: WorkerServiceProtocol = WorkerService.shared,
        pagesService: PagesServiceProtocol = PagesService.shared,
        tunnelService: TunnelServiceProtocol = TunnelService.shared,
        kvService: KVServiceProtocol = KVService.shared,
        r2Service: R2ServiceProtocol = R2Service.shared,
        d1Service: D1ServiceProtocol = D1Service.shared
    ) {
        self.zoneService = zoneService
        self.workerService = workerService
        self.pagesService = pagesService
        self.tunnelService = tunnelService
        self.kvService = kvService
        self.r2Service = r2Service
        self.d1Service = d1Service
        super.init()
        
        NotificationCenter.default.publisher(for: .recentZonesDidUpdate)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshRecentZones()
            }
            .store(in: &cancellables)
    }
    
    public func refreshRecentZones() {
        self.recentZones = RecentZonesManager.shared.getRecentZones(from: self.zones, limit: 3)
        self.fetchRecentSparklines()
        self.syncTopZoneToWidget()
    }
    
    var activeZonesCount: Int {
        zones.filter { $0.status.lowercased() == "active" }.count
    }
    
    var healthyTunnelsCount: Int {
        tunnels.filter { $0.isHealthy }.count
    }
    
    var totalStorageCount: Int {
        kvCount + r2Count + d1Count
    }
    
    var timeGreeting: LocalizedStringKey {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<18: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    func resetState() {
        self.zones = []
        self.workers = []
        self.pages = []
        self.tunnels = []
        self.kvCount = 0
        self.r2Count = 0
        self.d1Count = 0
        self.sparklines = [:]
        self.resetLoadingState()
    }
    
    func fetchDashboard(isRefresh: Bool = false) async {
        if !isRefresh && hasFetchedData && !isStale { return }
        
        let scopedKey = SWRCacheStore.accountScopedKey("dashboard_overview_snapshot")
        
        // 1. [Stale] 0ms 尝试从缓存预加载
        if !hasFetchedData, let cached = await SWRCacheStore.shared.get(forKey: scopedKey, as: DashboardSnapshot.self) {
            await MainActor.run {
                self.zones = cached.zones
                self.workers = cached.workers
                self.pages = cached.pages
                self.tunnels = cached.tunnels
                self.kvCount = cached.kvCount
                self.r2Count = cached.r2Count
                self.d1Count = cached.d1Count
                self.hasFetchedData = true
                self.refreshRecentZones()
                self.syncTopZoneToWidget()
            }
        }
        
        // 2. [Revalidate / Refresh] 统一执行前台/下拉拉取
        await executeLoadingTask(clearError: isRefresh) {
            // A. 获取账户列表
            let fetchedAccounts = (try? await self.zoneService.getAccounts()) ?? []
            if !fetchedAccounts.isEmpty {
                self.accounts = fetchedAccounts
                let activeEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
                let currentAcc = fetchedAccounts.first(where: { $0.name == activeEmail || $0.id == activeEmail }) ?? fetchedAccounts.first
                self.selectedAccount = currentAcc
            }
            
            // B. 获取域名列表
            if let fetchedZones = try? await self.zoneService.getZones().0 {
                self.zones = fetchedZones
                self.refreshRecentZones()
                // Fallback: 如果 getAccounts() 无返回（如普通 Zone 权限 Token），从 Zones 列表自动提取关联的 Account
                if self.selectedAccount == nil, let zoneAccount = fetchedZones.first?.account {
                    self.selectedAccount = Account(id: zoneAccount.id, name: zoneAccount.name ?? "Cloudflare Account")
                }
            }
            
            // C. 获取开发者全套资源
            if let accountId = self.selectedAccount?.id, !accountId.isEmpty {
                async let fetchW = try? self.workerService.getWorkers(accountId: accountId)
                async let fetchP = try? self.pagesService.getPagesProjects(accountId: accountId)
                async let fetchT = try? self.tunnelService.getTunnels(accountId: accountId)
                async let fetchK = try? self.kvService.getKVNamespaces(accountId: accountId)
                async let fetchR = try? self.r2Service.getR2Buckets(accountId: accountId)
                async let fetchD = try? self.d1Service.getD1Databases(accountId: accountId)
                
                let (w, p, t, k, r, d) = await (fetchW, fetchP, fetchT, fetchK, fetchR, fetchD)
                
                if let w { self.workers = w }
                if let p { self.pages = p }
                if let t { self.tunnels = t }
                if let k { self.kvCount = k.count }
                if let r { self.r2Count = r.count }
                if let d { self.d1Count = d.count }
            }
            
            // D. 持久化最新非空快照
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
                self.syncTopZoneToWidget()
            }
        }
    }
    
    /// 获取近期活跃域名的 24h 流量 Sparkline 数据
    private func fetchRecentSparklines() {
        let activeRecentIds = recentZones.filter { $0.status.lowercased() == "active" }.map { $0.id }
        guard !activeRecentIds.isEmpty else { return }
        
        Task {
            // 1. 优先读取已有的 SWR 本地缓存
            for id in activeRecentIds {
                if let cached = await SWRCacheStore.shared.get(forKey: "zone_sparkline_\(id)", as: ZoneSparklineCache.self) {
                    await MainActor.run {
                        self.sparklines[id] = cached
                    }
                }
            }
            
            // 2. 批量拉取实时 24h 流量点位
            if let batchMap = try? await AnalyticsService.shared.getBatchZonesSparklines(zoneTags: activeRecentIds) {
                await MainActor.run {
                    for (id, cache) in batchMap {
                        self.sparklines[id] = cache
                    }
                }
                for (id, cache) in batchMap {
                    await SWRCacheStore.shared.set(cache, forKey: "zone_sparkline_\(id)")
                }
            }
        }
    }
    
    private func syncTopZoneToWidget() {
        guard let topZone = recentZones.first ?? zones.first else { return }
        let current = WidgetDataStore.shared.loadZoneSnapshot()
        let snap = ZoneWidgetSnapshot(
            id: topZone.id,
            name: topZone.name,
            status: topZone.status,
            plan: topZone.plan?.name ?? "Free Plan",
            requests24h: current.id == topZone.id ? current.requests24h : 0,
            cachedRatio: current.id == topZone.id ? current.cachedRatio : 0.85,
            threats24h: current.id == topZone.id ? current.threats24h : 0,
            isProxied: !topZone.paused,
            isSSLEnabled: true,
            lastUpdated: Date()
        )
        WidgetDataStore.shared.saveZoneSnapshot(snap)
    }
}
