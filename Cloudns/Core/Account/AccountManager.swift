import Foundation
import SwiftUI
import Combine

@MainActor
class AccountManager: ObservableObject {
    static let shared = AccountManager()
    
    @Published var accountEmails: [String] = []
    
    /// Backward-compatibility accessor for account list without exposing keys in memory
    public var accounts: [String: String] {
        var dict: [String: String] = [:]
        for email in accountEmails {
            dict[email] = ""
        }
        return dict
    }
    
    @AppStorage(AppStorageKey.activeAccountEmail) var activeEmail: String = ""
    @AppStorage(AppStorageKey.isLoggedIn) var isLoggedIn: Bool = false
    
    private let serviceName = "com.cloudflare.api"
    
    private init() {
        migrateLegacyAccountIfNeeded()
        loadAccounts()
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
        loadAccounts()
    }
    
    func switchAccount(to email: String) {
        guard accountEmails.contains(email) else { return }
        activeEmail = email
        HapticManager.impact(.medium)
        NotificationCenter.default.post(name: .accountSwitched, object: nil)
    }
    
    func removeAccount(email: String) {
        KeychainHelper.standard.delete(service: serviceName, account: email)
        loadAccounts() // This will also handle fallback if the active account was deleted
        NotificationCenter.default.post(name: .accountSwitched, object: nil)
    }
    
    func logoutAll() {
        for email in accountEmails {
            KeychainHelper.standard.delete(service: serviceName, account: email)
        }
        activeEmail = ""
        isLoggedIn = false
        accountEmails.removeAll()
        NotificationCenter.default.post(name: .accountSwitched, object: nil)
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
