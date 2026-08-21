import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - WidgetDataStore

public final class WidgetDataStore: @unchecked Sendable {
    public static let shared = WidgetDataStore()
    
    public static let appGroupIdentifier = "group.com.lbyan.Cloudns"
    
    private let userDefaults: UserDefaults
    
    private enum Keys {
        static let zoneSnapshot = "cloudns.widget.zone.snapshot"
        static let workerSnapshot = "cloudns.widget.worker.snapshot"
        static let pagesSnapshot = "cloudns.widget.pages.snapshot"
        static let statusSnapshot = "cloudns.widget.status.snapshot"
        static let allZonesList = "cloudns.widget.zones.all"
    }
    
    private var containerFolderURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetDataStore.appGroupIdentifier)
    }
    
    private init() {
        if let sharedDefaults = UserDefaults(suiteName: WidgetDataStore.appGroupIdentifier) {
            self.userDefaults = sharedDefaults
        } else {
            self.userDefaults = .standard
        }
    }
    
    // MARK: - Zone Snapshot Operations
    
    public func saveZoneSnapshot(_ snapshot: ZoneWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        userDefaults.set(data, forKey: Keys.zoneSnapshot)
        userDefaults.synchronize()
        if let fileURL = containerFolderURL?.appendingPathComponent("zone_snapshot.json") {
            try? data.write(to: fileURL, options: .atomic)
        }
        notifyWidgetsToReload()
    }
    
    public func loadZoneSnapshot() -> ZoneWidgetSnapshot {
        if let data = userDefaults.data(forKey: Keys.zoneSnapshot),
           let snapshot = try? JSONDecoder().decode(ZoneWidgetSnapshot.self, from: data) {
            return snapshot
        }
        if let fileURL = containerFolderURL?.appendingPathComponent("zone_snapshot.json"),
           let data = try? Data(contentsOf: fileURL),
           let snapshot = try? JSONDecoder().decode(ZoneWidgetSnapshot.self, from: data) {
            return snapshot
        }
        return .placeholder
    }
    
    // MARK: - Pre-fetch & Sync Zone Snapshot with Analytics
    
    public func syncZoneWithAnalytics(zone: Zone) {
        let current = loadZoneSnapshot()
        
        // 1. [Immediate Stage] 立即写入基础快照（保留当前已有的流量或设为轻量初始态，确保 0ms 域名与套餐即刻更新）
        let initialSnap = ZoneWidgetSnapshot(
            id: zone.id,
            name: zone.name,
            status: zone.status,
            plan: zone.plan?.name ?? "Free Plan",
            requests24h: current.id == zone.id ? current.requests24h : 0,
            cachedRatio: current.id == zone.id ? current.cachedRatio : 0.85,
            threats24h: current.id == zone.id ? current.threats24h : 0,
            isProxied: !zone.paused,
            isSSLEnabled: true,
            lastUpdated: Date()
        )
        saveZoneSnapshot(initialSnap)
        
        // 2. [Background Stage] 异步自动拉取该域名的 24 小时真实流量分析数据并更新小组件
        Task {
            // A. 先检查本地 SWR 是否已有 24h 分析缓存
            let scopedKey = SWRCacheStore.accountScopedKey("zone_analytics_\(zone.id)_1")
            if let cached = await SWRCacheStore.shared.get(forKey: scopedKey, as: ZoneAnalyticsSnapshot.self) {
                var totalReq = 0
                var totalBytes = 0
                var totalCachedReq = 0
                var totalThreats = 0
                for item in cached.dataPoints {
                    totalReq += item.sum.requests
                    totalBytes += item.sum.bytes
                    totalCachedReq += item.sum.cachedRequests
                    totalThreats += item.sum.threats ?? 0
                }
                let ratio = totalReq > 0 ? Double(totalCachedReq) / Double(totalReq) : 0.85
                let fullSnap = ZoneWidgetSnapshot(
                    id: zone.id,
                    name: zone.name,
                    status: zone.status,
                    plan: zone.plan?.name ?? "Free Plan",
                    requests24h: totalReq,
                    bytes24h: totalBytes,
                    cachedRatio: ratio,
                    threats24h: totalThreats,
                    isProxied: !zone.paused,
                    isSSLEnabled: true,
                    lastUpdated: Date()
                )
                self.saveZoneSnapshot(fullSnap)
            }
            
            // B. 异步轻量请求 GraphQL 24h 流量快照
            if let analytics = try? await AnalyticsService.shared.getDashboardAnalytics(zoneTag: zone.id, days: 1),
               let zoneObj = analytics.viewer.zones?.first {
                let groups = zoneObj.httpRequests1hGroups ?? []
                var totalReq = 0
                var totalBytes = 0
                var totalCachedReq = 0
                var totalThreats = 0
                for item in groups {
                    totalReq += item.sum.requests
                    totalBytes += item.sum.bytes
                    totalCachedReq += item.sum.cachedRequests
                    totalThreats += item.sum.threats ?? 0
                }
                let ratio = totalReq > 0 ? Double(totalCachedReq) / Double(totalReq) : 0.85
                let fullSnap = ZoneWidgetSnapshot(
                    id: zone.id,
                    name: zone.name,
                    status: zone.status,
                    plan: zone.plan?.name ?? "Free Plan",
                    requests24h: totalReq,
                    bytes24h: totalBytes,
                    cachedRatio: ratio,
                    threats24h: totalThreats,
                    isProxied: !zone.paused,
                    isSSLEnabled: true,
                    lastUpdated: Date()
                )
                self.saveZoneSnapshot(fullSnap)
            }
        }
    }
    
    // MARK: - Worker Snapshot Operations
    
    public func saveWorkerSnapshot(_ snapshot: WorkerWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        userDefaults.set(data, forKey: Keys.workerSnapshot)
        userDefaults.synchronize()
        if let fileURL = containerFolderURL?.appendingPathComponent("worker_snapshot.json") {
            try? data.write(to: fileURL, options: .atomic)
        }
        notifyWidgetsToReload()
    }
    
    public func loadWorkerSnapshot() -> WorkerWidgetSnapshot {
        if let data = userDefaults.data(forKey: Keys.workerSnapshot),
           let snapshot = try? JSONDecoder().decode(WorkerWidgetSnapshot.self, from: data) {
            return snapshot
        }
        if let fileURL = containerFolderURL?.appendingPathComponent("worker_snapshot.json"),
           let data = try? Data(contentsOf: fileURL),
           let snapshot = try? JSONDecoder().decode(WorkerWidgetSnapshot.self, from: data) {
            return snapshot
        }
        return .placeholder
    }
    
    public func syncWorkerWithAnalytics(script: WorkerScript, accountId: String) {
        let current = loadWorkerSnapshot()
        let initialSnap = WorkerWidgetSnapshot(
            id: script.id,
            name: script.id,
            requests24h: current.id == script.id ? current.requests24h : 0,
            errors24h: current.id == script.id ? current.errors24h : 0,
            cpuTimeMs: current.id == script.id ? current.cpuTimeMs : 1.5,
            successRate: current.id == script.id ? current.successRate : 0.999,
            lastUpdated: Date()
        )
        saveWorkerSnapshot(initialSnap)
        
        Task {
            if let items = try? await AnalyticsService.shared.getWorkerAnalytics(accountId: accountId, scriptName: script.id, days: 1) {
                var totalReq = 0
                var totalErr = 0
                var totalCpu: Double = 0
                for item in items {
                    totalReq += item.sum?.requests ?? 0
                    totalErr += item.sum?.errors ?? 0
                    if let p50 = item.quantiles?.cpuTimeP50 {
                        totalCpu = Double(p50) / 1000.0 // Convert microseconds to ms if applicable
                    }
                }
                let success = totalReq > 0 ? Double(max(0, totalReq - totalErr)) / Double(totalReq) : 1.0
                let fullSnap = WorkerWidgetSnapshot(
                    id: script.id,
                    name: script.id,
                    requests24h: totalReq,
                    errors24h: totalErr,
                    cpuTimeMs: totalCpu > 0 ? totalCpu : 1.8,
                    successRate: success,
                    lastUpdated: Date()
                )
                self.saveWorkerSnapshot(fullSnap)
            }
        }
    }
    
    // MARK: - Pages Snapshot Operations
    
    public func savePagesSnapshot(_ snapshot: PagesWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        userDefaults.set(data, forKey: Keys.pagesSnapshot)
        userDefaults.synchronize()
        if let fileURL = containerFolderURL?.appendingPathComponent("pages_snapshot.json") {
            try? data.write(to: fileURL, options: .atomic)
        }
        notifyWidgetsToReload()
    }
    
    public func loadPagesSnapshot() -> PagesWidgetSnapshot {
        if let data = userDefaults.data(forKey: Keys.pagesSnapshot),
           let snapshot = try? JSONDecoder().decode(PagesWidgetSnapshot.self, from: data) {
            return snapshot
        }
        if let fileURL = containerFolderURL?.appendingPathComponent("pages_snapshot.json"),
           let data = try? Data(contentsOf: fileURL),
           let snapshot = try? JSONDecoder().decode(PagesWidgetSnapshot.self, from: data) {
            return snapshot
        }
        return .placeholder
    }
    
    public func syncPagesWithAnalytics(project: PagesProject, accountId: String) {
        let current = loadPagesSnapshot()
        let initialSnap = PagesWidgetSnapshot(
            id: project.id,
            name: project.name,
            subdomain: project.subdomain ?? "\(project.name).pages.dev",
            productionBranch: project.productionBranch ?? "main",
            latestStatus: "active",
            requests24h: current.id == project.id ? current.requests24h : 0,
            errors24h: current.id == project.id ? current.errors24h : 0,
            lastUpdated: Date()
        )
        savePagesSnapshot(initialSnap)
        
        Task {
            if let items = try? await AnalyticsService.shared.getPagesAnalytics(accountId: accountId, projectName: project.name, days: 1) {
                var totalReq = 0
                var totalErr = 0
                for item in items {
                    totalReq += item.sum?.requests ?? 0
                    totalErr += item.sum?.errors ?? 0
                }
                let fullSnap = PagesWidgetSnapshot(
                    id: project.id,
                    name: project.name,
                    subdomain: project.subdomain ?? "\(project.name).pages.dev",
                    productionBranch: project.productionBranch ?? "main",
                    latestStatus: "active",
                    requests24h: totalReq,
                    errors24h: totalErr,
                    lastUpdated: Date()
                )
                self.savePagesSnapshot(fullSnap)
            }
        }
    }
    
    // MARK: - CF Status Snapshot Operations
    
    public func saveStatusSnapshot(_ snapshot: CFStatusWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        userDefaults.set(data, forKey: Keys.statusSnapshot)
        userDefaults.synchronize()
        if let fileURL = containerFolderURL?.appendingPathComponent("status_snapshot.json") {
            try? data.write(to: fileURL, options: .atomic)
        }
        notifyWidgetsToReload()
    }
    
    public func loadStatusSnapshot() -> CFStatusWidgetSnapshot {
        if let data = userDefaults.data(forKey: Keys.statusSnapshot),
           let snapshot = try? JSONDecoder().decode(CFStatusWidgetSnapshot.self, from: data) {
            return snapshot
        }
        if let fileURL = containerFolderURL?.appendingPathComponent("status_snapshot.json"),
           let data = try? Data(contentsOf: fileURL),
           let snapshot = try? JSONDecoder().decode(CFStatusWidgetSnapshot.self, from: data) {
            return snapshot
        }
        return .placeholder
    }
    
    // MARK: - Reload Trigger
    
    public func notifyWidgetsToReload() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "ZoneOverviewWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "WorkerOverviewWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "PagesOverviewWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "SystemStatusWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "QuickActionsWidget")
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    public func clearAll() {
        userDefaults.removeObject(forKey: Keys.zoneSnapshot)
        userDefaults.removeObject(forKey: Keys.workerSnapshot)
        userDefaults.removeObject(forKey: Keys.pagesSnapshot)
        userDefaults.removeObject(forKey: Keys.statusSnapshot)
        userDefaults.removeObject(forKey: Keys.allZonesList)
        
        if let container = containerFolderURL {
            try? FileManager.default.removeItem(at: container.appendingPathComponent("zone_snapshot.json"))
            try? FileManager.default.removeItem(at: container.appendingPathComponent("worker_snapshot.json"))
            try? FileManager.default.removeItem(at: container.appendingPathComponent("pages_snapshot.json"))
            try? FileManager.default.removeItem(at: container.appendingPathComponent("status_snapshot.json"))
        }
        
        notifyWidgetsToReload()
    }
}
