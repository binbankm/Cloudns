import Foundation

// MARK: - AppStorage & UserDefaults Keys

public enum AppStorageKey: Sendable {
    public nonisolated static let isLoggedIn = "isLoggedIn"
    public nonisolated static let activeAccountEmail = "activeAccountEmail"
    public nonisolated static let activeAccountId = "activeAccountId"
    public nonisolated static let hasSeenOnboarding = "hasSeenOnboarding"
    public nonisolated static let isAppLockEnabled = "isAppLockEnabled"
    public nonisolated static let autoLockTimeout = "autoLockTimeout"
    public nonisolated static let lastBackgroundTime = "lastBackgroundTime"
    public nonisolated static let themePreference = "themePreference"
    public nonisolated static let themeColor = "themeColor"
    public nonisolated static let appLanguage = "appLanguage"
    public nonisolated static let appIcon = "appIcon"
    public nonisolated static let hapticsEnabled = "hapticsEnabled"
    public nonisolated static let hasRunBeforeAppInstallation = "hasRunBeforeAppInstallation"
    public nonisolated static let keychainService = "com.cloudflare.api"
    public nonisolated static let recentZoneIds = "cloudns.recent.zone.ids"
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
