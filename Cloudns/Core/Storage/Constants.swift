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
    nonisolated public static let keychainService = "com.cloudflare.api"
}

// MARK: - Type-Safe Notifications

public extension Notification.Name {
    nonisolated static let zoneDeleted = Notification.Name("ZoneDeleted")
    nonisolated static let zoneUpdated = Notification.Name("ZoneUpdated")
    nonisolated static let accountSwitched = Notification.Name("AccountSwitched")
    nonisolated static let appWillEnterForeground = Notification.Name("AppWillEnterForeground")
}
