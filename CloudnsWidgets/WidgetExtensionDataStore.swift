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
        static let activeAccount = "cloudns.widget.active.account"
        static let zoneSnapshot = "cloudns.widget.zone.snapshot"
        static let workerSnapshot = "cloudns.widget.worker.snapshot"
        static let pagesSnapshot = "cloudns.widget.pages.snapshot"
        static let statusSnapshot = "cloudns.widget.status.snapshot"
        static let allZonesList = "cloudns.widget.zones.all"
    }
    
    private var activeAccountScope: String {
        let stored = userDefaults.string(forKey: Keys.activeAccount) ?? "default"
        return stored.isEmpty ? "default" : stored
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
    
    // MARK: - Zone Snapshot Operations
    
    public func saveZoneSnapshot(_ snapshot: ZoneWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        userDefaults.set(data, forKey: scopedKey(Keys.zoneSnapshot))
        userDefaults.set(data, forKey: Keys.zoneSnapshot)
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
        if let data = userDefaults.data(forKey: Keys.zoneSnapshot),
           let snapshot = try? JSONDecoder().decode(ZoneWidgetSnapshot.self, from: data) {
            return snapshot
        }
        return .placeholder
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
        if let data = userDefaults.data(forKey: Keys.workerSnapshot),
           let snapshot = try? JSONDecoder().decode(WorkerWidgetSnapshot.self, from: data) {
            return snapshot
        }
        return .placeholder
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
        if let data = userDefaults.data(forKey: Keys.pagesSnapshot),
           let snapshot = try? JSONDecoder().decode(PagesWidgetSnapshot.self, from: data) {
            return snapshot
        }
        return .placeholder
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
        if let data = userDefaults.data(forKey: Keys.statusSnapshot),
           let snapshot = try? JSONDecoder().decode(CFStatusWidgetSnapshot.self, from: data) {
            return snapshot
        }
        return .placeholder
    }
    
    // MARK: - Reload Trigger
    
    private let reloadLock = NSLock()
    private var widgetReloadTask: Task<Void, Never>?
    
    public func notifyWidgetsToReload() {
        #if canImport(WidgetKit)
        reloadLock.lock()
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
        reloadLock.unlock()
        #endif
    }
}
