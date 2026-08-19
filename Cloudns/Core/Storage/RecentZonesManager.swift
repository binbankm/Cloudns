import Foundation

// MARK: - RecentZonesManager

public final class RecentZonesManager: @unchecked Sendable {
    public static let shared = RecentZonesManager()
    
    private let maxHistoryCount = 10
    
    private init() {}
    
    public var recentZoneIds: [String] {
        get {
            UserDefaults.standard.stringArray(forKey: AppStorageKey.recentZoneIds) ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppStorageKey.recentZoneIds)
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
}
