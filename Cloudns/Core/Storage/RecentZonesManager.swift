import Foundation

// MARK: - RecentZonesManager

@MainActor
public final class RecentZonesManager {
    public static let shared = RecentZonesManager()
    
    private let maxHistoryCount = 10
    
    private init() {}
    
    private var storageKey: String {
        let email = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail)
            .flatMap { $0.isEmpty ? nil : $0 } ?? "default"
        return "recentZoneIds_\(email)"
    }
    
    public var recentZoneIds: [String] {
        get {
            UserDefaults.standard.stringArray(forKey: storageKey) ?? UserDefaults.standard.stringArray(forKey: AppStorageKey.recentZoneIds) ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: storageKey)
        }
    }
    
    public func recordVisit(zoneId: String) {
        guard !zoneId.isEmpty else { return }
        var current = recentZoneIds.filter { $0 != zoneId }
        current.insert(zoneId, at: 0)
        if current.count > maxHistoryCount {
            current = Array(current.prefix(maxHistoryCount))
        }
        recentZoneIds = current
        
        NotificationCenter.default.post(name: .recentZonesDidUpdate, object: nil, userInfo: ["zoneId": zoneId])
    }
    
    public func removeZone(zoneId: String) {
        guard !zoneId.isEmpty else { return }
        let current = recentZoneIds.filter { $0 != zoneId }
        recentZoneIds = current
        NotificationCenter.default.post(name: .recentZonesDidUpdate, object: nil, userInfo: ["zoneId": zoneId])
    }
    
    public func getRecentZones(from allZones: [Zone], limit: Int = 3) -> [Zone] {
        let recents = recentZoneIds.compactMap { id in allZones.first(where: { $0.id == id }) }
        if recents.count >= limit {
            return Array(recents.prefix(limit))
        }
        var result = recents
        for zone in allZones where !result.contains(where: { $0.id == zone.id }) {
            result.append(zone)
            if result.count >= limit { break }
        }
        return result
    }
    
    public func clearAll() {
        recentZoneIds = []
        UserDefaults.standard.removeObject(forKey: AppStorageKey.recentZoneIds)
        NotificationCenter.default.post(name: .recentZonesDidUpdate, object: nil)
    }
}
