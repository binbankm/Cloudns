import Combine
import Foundation

// MARK: - Notification Extension

public extension Notification.Name {
    static let accountSwitched = Notification.Name("com.cloudns.accountSwitched")
}

// MARK: - Account Manager

@MainActor
public final class AccountManager: ObservableObject {
    public static let shared = AccountManager()

    private let keychainService = "com.cloudflare.api"
    private let accountsStorageKey = "com.cloudns.accounts.list"
    private let activeAccountIdKey = "com.cloudns.activeAccountId"

    @Published public private(set) var accounts: [CloudflareAccount] = []
    @Published public private(set) var activeAccountId: String?

    public var currentAccount: CloudflareAccount? {
        guard let activeAccountId else { return accounts.first }
        return accounts.first { $0.id == activeAccountId } ?? accounts.first
    }

    public var hasActiveAccount: Bool {
        currentAccount != nil
    }

    private init() {
        loadAccounts()
    }

    // MARK: - Persistence & Loading

    private func loadAccounts() {
        if let data = UserDefaults.standard.data(forKey: accountsStorageKey),
           let decoded = try? JSONDecoder().decode([CloudflareAccount].self, from: data) {
            accounts = decoded
        } else {
            accounts = []
        }

        let savedActiveId = UserDefaults.standard.string(forKey: activeAccountIdKey)
        if let savedActiveId, accounts.contains(where: { $0.id == savedActiveId }) {
            activeAccountId = savedActiveId
        } else {
            activeAccountId = accounts.first?.id
            UserDefaults.standard.set(activeAccountId, forKey: activeAccountIdKey)
        }
    }

    private func persistAccounts() {
        if let encoded = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(encoded, forKey: accountsStorageKey)
        }
        UserDefaults.standard.set(activeAccountId, forKey: activeAccountIdKey)
        UserDefaults.standard.set(activeAccountId, forKey: AppStorageKey.activeAccountId)
        if let email = currentAccount?.email {
            UserDefaults.standard.set(email, forKey: AppStorageKey.activeAccountEmail)
            UserDefaults.standard.set(true, forKey: AppStorageKey.isLoggedIn)
        } else {
            UserDefaults.standard.removeObject(forKey: AppStorageKey.activeAccountEmail)
            UserDefaults.standard.set(false, forKey: AppStorageKey.isLoggedIn)
        }
    }

    // MARK: - Account Operations

    /// Adds or updates an account with pure Global API Key stored securely in Keychain
    @discardableResult
    public func saveAccount(name: String, email: String, apiKey: String) -> CloudflareAccount {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? cleanEmail : name

        // Check if an account with the same email already exists
        let account: CloudflareAccount
        if let existingIndex = accounts.firstIndex(where: { $0.email.lowercased() == cleanEmail }) {
            var updated = accounts[existingIndex]
            updated.name = cleanName
            accounts[existingIndex] = updated
            account = updated
        } else {
            account = CloudflareAccount(name: cleanName, email: cleanEmail)
            accounts.append(account)
        }

        // Save 37-character Global API Key securely to Keychain
        KeychainHelper.standard.saveString(cleanKey, service: keychainService, account: account.id)

        // If this is the only account or none is active, make it active
        if activeAccountId == nil || accounts.count == 1 {
            switchAccount(to: account.id)
        } else {
            persistAccounts()
        }

        return account
    }

    /// Updates the display name for an existing account and persists it
    public func updateAccountName(id: String, name: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        guard let index = accounts.firstIndex(where: { $0.id == id }) else { return }
        accounts[index].name = cleanName
        persistAccounts()
    }

    /// Switches the currently active account seamlessly
    public func switchAccount(to id: String) {
        guard accounts.contains(where: { $0.id == id }) else { return }
        guard activeAccountId != id else { return }

        activeAccountId = id
        persistAccounts()

        GentleHaptics.selection()
        NotificationCenter.default.post(name: .accountSwitched, object: nil)
    }

    /// Removes an account and securely deletes its credential from Keychain
    public func deleteAccount(id: String) {
        KeychainHelper.standard.delete(service: keychainService, account: id)
        accounts.removeAll { $0.id == id }

        if activeAccountId == id {
            activeAccountId = accounts.first?.id
            NotificationCenter.default.post(name: .accountSwitched, object: nil)
        }

        persistAccounts()
        GentleHaptics.warning()
    }

    /// Reads the Global API Key from Keychain for the specified or current active account
    public func getApiKey(for accountId: String? = nil) -> String? {
        let targetId = accountId ?? activeAccountId
        guard let targetId else { return nil }
        return KeychainHelper.standard.readString(service: keychainService, account: targetId)
    }
}
