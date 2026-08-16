import Foundation

// MARK: - AppStorage & UserDefaults Keys

public enum AppStorageKey {
    public static let isLoggedIn = "isLoggedIn"
    public static let activeAccountEmail = "activeAccountEmail"
    public static let hasSeenOnboarding = "hasSeenOnboarding"
    public static let isAppLockEnabled = "isAppLockEnabled"
    public static let themePreference = "themePreference"
    public static let appLanguage = "appLanguage"
    public static let hapticsEnabled = "hapticsEnabled"
}

// MARK: - Type-Safe Notifications

public extension Notification.Name {
    static let zoneDeleted = Notification.Name("ZoneDeleted")
    static let zoneUpdated = Notification.Name("ZoneUpdated")
    static let accountSwitched = Notification.Name("AccountSwitched")
}
