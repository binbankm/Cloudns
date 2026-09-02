import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - WidgetDataStore

@MainActor
public final class WidgetDataStore {
    public static let shared = WidgetDataStore()
    
    public static let appGroupIdentifier = "group.com.lbyan.Cloudns"
    
    private let userDefaults: UserDefaults
    
    private enum Keys {
        static let activeAccount = "cloudns.widget.active.account"
        static let zoneSnapshot = "cloudns.widget.zone.snapshot"
        static let workerSnapshot = "cloudns.widget.worker.snapshot"
        static let pagesSnapshot = "cloudns.widget.pages.snapshot"
        static let statusSnapshot = "cloudns.widget.status.snapshot"
        static let allZonesList = "cloudns.widget.zones.all"
    }
    
    private var activeAccountScope: String {
        if let stored = userDefaults.string(forKey: Keys.activeAccount), !stored.isEmpty {
            return stored
        }
        let email = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? "default"
        return email.isEmpty ? "default" : email
    }
    
    private func scopedKey(_ base: String) -> String {
        "\(base)_\(activeAccountScope)"
    }
    
    private func scopedFileName(_ base: String) -> String {
        let cleanScope = activeAccountScope.replacingOccurrences(of: "@", with: "_").replacingOccurrences(of: ".", with: "_")
        return "\(base)_\(cleanScope).json"
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
    
    public func syncActiveAccount(_ email: String) {
        userDefaults.set(email, forKey: Keys.activeAccount)
        notifyWidgetsToReload()
    }
    
    // MARK: - Zone Snapshot Operations
    
    public func saveZoneSnapshot(_ snapshot: ZoneWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        userDefaults.set(data, forKey: scopedKey(Keys.zoneSnapshot))
        userDefaults.set(data, forKey: Keys.zoneSnapshot) // Fallback for backward compat
        if let fileURL = containerFolderURL?.appendingPathComponent(scopedFileName("zone_snapshot")) {
            try? data.write(to: fileURL, options: .atomic)
        }
        notifyWidgetsToReload()
    }
    
    public func loadZoneSnapshot() -> ZoneWidgetSnapshot {
        if let data = userDefaults.data(forKey: scopedKey(Keys.zoneSnapshot)),
           let snapshot = try? JSONDecoder().decode(ZoneWidgetSnapshot.self, from: data) {
            return snapshot
        }
        if let fileURL = containerFolderURL?.appendingPathComponent(scopedFileName("zone_snapshot")),
           let data = try? Data(contentsOf: fileURL),
           let snapshot = try? JSONDecoder().decode(ZoneWidgetSnapshot.self, from: data) {
            return snapshot
        }
        return .placeholder
    }
    
    // MARK: - Pre-fetch & Sync Zone Snapshot with Analytics
    
    public func syncZoneWithAnalytics(zone: Zone) {
        let current = loadZoneSnapshot()
        
        let initialSnap = ZoneWidgetSnapshot(
            id: zone.id,
            name: zone.name,
            status: zone.status,
            plan: zone.plan?.name ?? "Free Plan",
            requests24h: current.id == zone.id ? current.requests24h : 0,
            bytes24h: current.id == zone.id ? current.bytes24h : 0,
            cachedRatio: current.id == zone.id ? current.cachedRatio : 0.85,
            threats24h: current.id == zone.id ? current.threats24h : 0,
            isProxied: !zone.paused,
            isSSLEnabled: true,
            lastUpdated: Date()
        )
        saveZoneSnapshot(initialSnap)
        
        Task {
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
        userDefaults.set(data, forKey: scopedKey(Keys.workerSnapshot))
        userDefaults.set(data, forKey: Keys.workerSnapshot)
        if let fileURL = containerFolderURL?.appendingPathComponent(scopedFileName("worker_snapshot")) {
            try? data.write(to: fileURL, options: .atomic)
        }
        notifyWidgetsToReload()
    }
    
    public func loadWorkerSnapshot() -> WorkerWidgetSnapshot {
        if let data = userDefaults.data(forKey: scopedKey(Keys.workerSnapshot)),
           let snapshot = try? JSONDecoder().decode(WorkerWidgetSnapshot.self, from: data) {
            return snapshot
        }
        if let fileURL = containerFolderURL?.appendingPathComponent(scopedFileName("worker_snapshot")),
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
        userDefaults.set(data, forKey: scopedKey(Keys.pagesSnapshot))
        userDefaults.set(data, forKey: Keys.pagesSnapshot)
        if let fileURL = containerFolderURL?.appendingPathComponent(scopedFileName("pages_snapshot")) {
            try? data.write(to: fileURL, options: .atomic)
        }
        notifyWidgetsToReload()
    }
    
    public func loadPagesSnapshot() -> PagesWidgetSnapshot {
        if let data = userDefaults.data(forKey: scopedKey(Keys.pagesSnapshot)),
           let snapshot = try? JSONDecoder().decode(PagesWidgetSnapshot.self, from: data) {
            return snapshot
        }
        if let fileURL = containerFolderURL?.appendingPathComponent(scopedFileName("pages_snapshot")),
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
        userDefaults.set(data, forKey: scopedKey(Keys.statusSnapshot))
        userDefaults.set(data, forKey: Keys.statusSnapshot)
        if let fileURL = containerFolderURL?.appendingPathComponent(scopedFileName("status_snapshot")) {
            try? data.write(to: fileURL, options: .atomic)
        }
        notifyWidgetsToReload()
    }
    
    public func loadStatusSnapshot() -> CFStatusWidgetSnapshot {
        if let data = userDefaults.data(forKey: scopedKey(Keys.statusSnapshot)),
           let snapshot = try? JSONDecoder().decode(CFStatusWidgetSnapshot.self, from: data) {
            return snapshot
        }
        if let fileURL = containerFolderURL?.appendingPathComponent(scopedFileName("status_snapshot")),
           let data = try? Data(contentsOf: fileURL),
           let snapshot = try? JSONDecoder().decode(CFStatusWidgetSnapshot.self, from: data) {
            return snapshot
        }
        return .placeholder
    }
    
    // MARK: - Reload Trigger
    
    private var widgetReloadTask: Task<Void, Never>?
    
    public func notifyWidgetsToReload() {
        #if canImport(WidgetKit)
        widgetReloadTask?.cancel()
        widgetReloadTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            WidgetCenter.shared.reloadTimelines(ofKind: "ZoneOverviewWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "WorkerOverviewWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "PagesOverviewWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "SystemStatusWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "QuickActionsWidget")
        }
        #endif
    }
    
    public func clearAll() {
        userDefaults.removeObject(forKey: Keys.activeAccount)
        userDefaults.removeObject(forKey: Keys.zoneSnapshot)
        userDefaults.removeObject(forKey: Keys.workerSnapshot)
        userDefaults.removeObject(forKey: Keys.pagesSnapshot)
        userDefaults.removeObject(forKey: Keys.statusSnapshot)
        userDefaults.removeObject(forKey: Keys.allZonesList)
        
        if let container = containerFolderURL {
            let fm = FileManager.default
            if let contents = try? fm.contentsOfDirectory(at: container, includingPropertiesForKeys: nil) {
                for fileURL in contents where fileURL.pathExtension == "json" {
                    try? fm.removeItem(at: fileURL)
                }
            }
        }
        
        notifyWidgetsToReload()
    }
}
