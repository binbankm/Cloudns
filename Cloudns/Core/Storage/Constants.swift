import Foundation

// MARK: - AppStorage & UserDefaults Keys

public enum AppStorageKey: Sendable {
    nonisolated public static let isLoggedIn = "isLoggedIn"
    nonisolated public static let activeAccountEmail = "activeAccountEmail"
    nonisolated public static let hasSeenOnboarding = "hasSeenOnboarding"
    nonisolated public static let isAppLockEnabled = "isAppLockEnabled"
    nonisolated public static let autoLockTimeout = "autoLockTimeout"
    nonisolated public static let lastBackgroundTime = "lastBackgroundTime"
    nonisolated public static let themePreference = "themePreference"
    nonisolated public static let appLanguage = "appLanguage"
    nonisolated public static let hapticsEnabled = "hapticsEnabled"
    nonisolated public static let hasRunBeforeAppInstallation = "hasRunBeforeAppInstallation"
    nonisolated public static let keychainService = "com.cloudflare.api"
    nonisolated public static let recentZoneIds = "cloudns.recent.zone.ids"
}

// MARK: - Type-Safe Notifications

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
