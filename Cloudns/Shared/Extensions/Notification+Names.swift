import Foundation

// MARK: - Type-Safe Notification Names

public extension Notification.Name {
    nonisolated static let zoneDeleted = Notification.Name("com.cloudns.zoneDeleted")
    nonisolated static let zoneCreated = Notification.Name("com.cloudns.zoneCreated")
    nonisolated static let zoneUpdated = Notification.Name("com.cloudns.zoneUpdated")
    nonisolated static let developerResourceMutated = Notification.Name("com.cloudns.developerResourceMutated")
    nonisolated static let recentZonesDidUpdate = Notification.Name("com.cloudns.recentZonesDidUpdate")
    nonisolated static let accountSwitched = Notification.Name("com.cloudns.accountSwitched")
    nonisolated static let appWillEnterForeground = Notification.Name("com.cloudns.appWillEnterForeground")
    nonisolated static let localCachePurged = Notification.Name("com.cloudns.localCachePurged")
}
