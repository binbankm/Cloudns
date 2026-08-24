import Foundation
import SwiftUI
import Combine

@MainActor
final class AccountManager: ObservableObject {
    static let shared = AccountManager()
    
    @Published var accountEmails: [String] = []
    
    /// Backward-compatibility accessor for account list without exposing keys in memory
    @available(*, deprecated, renamed: "accountEmails")
    public var accounts: [String: String] {
        var dict: [String: String] = [:]
        for email in accountEmails {
            dict[email] = ""
        }
        return dict
    }
    
    @AppStorage(AppStorageKey.activeAccountEmail) var activeEmail: String = ""
    @AppStorage(AppStorageKey.isLoggedIn) var isLoggedIn: Bool = false
    
    private let serviceName = AppStorageKey.keychainService
    
    private init() {
        handleFirstLaunchAfterInstallIfNeeded()
        migrateLegacyAccountIfNeeded()
        loadAccounts()
    }
    
    private func handleFirstLaunchAfterInstallIfNeeded() {
        let hasRunKey = AppStorageKey.hasRunBeforeAppInstallation
        if !UserDefaults.standard.bool(forKey: hasRunKey) {
            // App was newly installed or re-installed after being deleted
            // Wipe stale residual keychain records from past installs
            KeychainHelper.standard.deleteAll(service: serviceName)
            KeychainHelper.standard.delete(service: serviceName, account: "email")
            KeychainHelper.standard.delete(service: serviceName, account: "apiKey")
            
            // Wipe local cached history, widget snapshots, SWR caches and AppLock
            RecentZonesManager.shared.clearAll()
            WidgetDataStore.shared.clearAll()
            
            self.activeEmail = ""
            self.isLoggedIn = false
            self.accountEmails = []
            
            UserDefaults.standard.set(false, forKey: AppStorageKey.isLoggedIn)
            UserDefaults.standard.set("", forKey: AppStorageKey.activeAccountEmail)
            UserDefaults.standard.set(false, forKey: AppStorageKey.isAppLockEnabled)
            UserDefaults.standard.set(false, forKey: AppStorageKey.hasSeenOnboarding)
            UserDefaults.standard.set(true, forKey: hasRunKey)
            
            Task {
                await SWRCacheStore.shared.clearAll()
                await CacheManager.shared.clearAllCaches()
            }
        }
    }
    
    func loadAccounts() {
        let allAccounts = KeychainHelper.standard.readAll(service: serviceName)
        self.accountEmails = Array(allAccounts.keys).sorted()
        
        // Ensure activeEmail is valid
        if !activeEmail.isEmpty, !accountEmails.contains(activeEmail) {
            // Active email no longer exists in Keychain
            if let first = accountEmails.first {
                activeEmail = first
            } else {
                activeEmail = ""
                isLoggedIn = false
            }
        }
        
        // If logged in but no active email, try to set one
        if activeEmail.isEmpty, let first = accountEmails.first {
            activeEmail = first
            isLoggedIn = true
        }
    }
    
    func getAPIKey(for email: String) -> String? {
        return KeychainHelper.standard.readString(service: serviceName, account: email)
    }
    
    func addAccount(email: String, apiKey: String) {
        KeychainHelper.standard.saveString(apiKey, service: serviceName, account: email)
        activeEmail = email
        isLoggedIn = true
        WidgetDataStore.shared.syncActiveAccount(email)
        loadAccounts()
    }
    
    func switchAccount(to email: String) {
        guard accountEmails.contains(email) else { return }
        activeEmail = email
        WidgetDataStore.shared.syncActiveAccount(email)
        HapticManager.impact(.medium)
        NotificationCenter.default.post(name: .accountSwitched, object: nil)
    }
    
    func removeAccount(email: String) {
        KeychainHelper.standard.delete(service: serviceName, account: email)
        loadAccounts() // This will also handle fallback if the active account was deleted
        if accountEmails.isEmpty {
            RecentZonesManager.shared.clearAll()
            WidgetDataStore.shared.clearAll()
            Task {
                await SWRCacheStore.shared.clearAll()
                await CacheManager.shared.clearAllCaches()
            }
        }
        NotificationCenter.default.post(name: .accountSwitched, object: nil)
    }
    
    func logoutAll() {
        for email in accountEmails {
            KeychainHelper.standard.delete(service: serviceName, account: email)
        }
        KeychainHelper.standard.deleteAll(service: serviceName)
        KeychainHelper.standard.delete(service: serviceName, account: "email")
        KeychainHelper.standard.delete(service: serviceName, account: "apiKey")
        
        RecentZonesManager.shared.clearAll()
        WidgetDataStore.shared.clearAll()
        
        activeEmail = ""
        isLoggedIn = false
        accountEmails.removeAll()
        
        UserDefaults.standard.set(false, forKey: AppStorageKey.isLoggedIn)
        UserDefaults.standard.set("", forKey: AppStorageKey.activeAccountEmail)
        UserDefaults.standard.set(false, forKey: AppStorageKey.isAppLockEnabled)
        
        Task {
            await SWRCacheStore.shared.clearAll()
            await CacheManager.shared.clearAllCaches()
        }
        
        NotificationCenter.default.post(name: .accountSwitched, object: nil)
        NotificationCenter.default.post(name: .localCachePurged, object: nil)
    }
    
    // Legacy migration
    func migrateLegacyAccountIfNeeded() {
        // If there's an old setup where account is "email" and "apiKey"
        if let oldEmail = KeychainHelper.standard.readString(service: serviceName, account: "email"),
           let oldKey = KeychainHelper.standard.readString(service: serviceName, account: "apiKey") {
            
            // It's a valid legacy format, migrate it to the new format
            KeychainHelper.standard.saveString(oldKey, service: serviceName, account: oldEmail)
            
            // Delete legacy keys
            KeychainHelper.standard.delete(service: serviceName, account: "email")
            KeychainHelper.standard.delete(service: serviceName, account: "apiKey")
            
            // Set active
            self.activeEmail = oldEmail
            self.isLoggedIn = true
        }
    }
}
