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
        WidgetCenter.shared.reloadTimelines(ofKind: "SystemStatusWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "QuickActionsWidget")
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
