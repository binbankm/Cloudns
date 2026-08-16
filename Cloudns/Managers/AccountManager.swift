import Foundation
import SwiftUI
import Combine

@MainActor
class AccountManager: ObservableObject {
    static let shared = AccountManager()
    
    @Published var accounts: [String: String] = [:] // [Email: APIKey]
    
    @AppStorage(AppStorageKey.activeAccountEmail) var activeEmail: String = ""
    @AppStorage(AppStorageKey.isLoggedIn) var isLoggedIn: Bool = false
    
    private let serviceName = "com.cloudflare.api"
    
    private init() {
        migrateLegacyAccountIfNeeded()
        loadAccounts()
    }
    
    func loadAccounts() {
        self.accounts = KeychainHelper.standard.readAll(service: serviceName)
        
        // Ensure activeEmail is valid
        if !activeEmail.isEmpty, accounts[activeEmail] == nil {
            // Active email no longer exists in Keychain
            if let first = accounts.keys.first {
                activeEmail = first
            } else {
                activeEmail = ""
                isLoggedIn = false
            }
        }
        
        // If logged in but no active email, try to set one
        if activeEmail.isEmpty, let first = accounts.keys.first {
            activeEmail = first
            isLoggedIn = true
        }
    }
    
    func addAccount(email: String, apiKey: String) {
        KeychainHelper.standard.saveString(apiKey, service: serviceName, account: email)
        activeEmail = email
        isLoggedIn = true
        loadAccounts()
    }
    
    func switchAccount(to email: String) {
        guard accounts.keys.contains(email) else { return }
        activeEmail = email
        HapticManager.impact(.medium)
        NotificationCenter.default.post(name: .accountSwitched, object: nil)
    }
    
    func removeAccount(email: String) {
        KeychainHelper.standard.delete(service: serviceName, account: email)
        loadAccounts() // This will also handle fallback if the active account was deleted
    }
    
    func logoutAll() {
        for email in accounts.keys {
            KeychainHelper.standard.delete(service: serviceName, account: email)
        }
        activeEmail = ""
        isLoggedIn = false
        accounts.removeAll()
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
