import Foundation
import Security

protocol KeychainHelperProtocol: Sendable {
    @discardableResult
    func save(_ data: Data, service: String, account: String) -> OSStatus
    func read(service: String, account: String) -> Data?
    func readAll(service: String) -> [String: String]
    @discardableResult
    func delete(service: String, account: String) -> OSStatus
    @discardableResult
    func deleteAll(service: String) -> OSStatus
    @discardableResult
    func saveString(_ string: String, service: String, account: String) -> OSStatus
    func readString(service: String, account: String) -> String?
}

final class KeychainHelper: KeychainHelperProtocol, Sendable {
    static let standard = KeychainHelper()
    
    init() {}
    
    @discardableResult
    func save(_ data: Data, service: String, account: String) -> OSStatus {
        let query = [
            kSecValueData: data,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ] as CFDictionary
        
        // Add data to keychain
        let status = SecItemAdd(query, nil)
        
        // Item already exists, thus update it
        if status == errSecDuplicateItem {
            let updateQuery = [
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecClass: kSecClassGenericPassword
            ] as CFDictionary
            
            let attributesToUpdate = [
                kSecValueData: data,
                kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ] as CFDictionary
            
            return SecItemUpdate(updateQuery, attributesToUpdate)
        }
        return status
    }
    
    func read(service: String, account: String) -> Data? {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        
        return (result as? Data)
    }
    func readAll(service: String) -> [String: String] {
        let query = [
            kSecAttrService: service,
            kSecClass: kSecClassGenericPassword,
            kSecReturnAttributes: true,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitAll
        ] as CFDictionary
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        
        var accounts: [String: String] = [:]
        
        if status == errSecSuccess, let items = result as? [[String: Any]] {
            for item in items {
                if let account = item[kSecAttrAccount as String] as? String,
                   let data = item[kSecValueData as String] as? Data,
                   let value = String(data: data, encoding: .utf8) {
                    accounts[account] = value
                }
            }
        }
        
        return accounts
    }
    
    @discardableResult
    func delete(service: String, account: String) -> OSStatus {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword
        ] as CFDictionary
        
        return SecItemDelete(query)
    }
    
    @discardableResult
    func deleteAll(service: String) -> OSStatus {
        let query = [
            kSecAttrService: service,
            kSecClass: kSecClassGenericPassword
        ] as CFDictionary
        
        return SecItemDelete(query)
    }
    
    // Convenience for Strings
    @discardableResult
    func saveString(_ string: String, service: String, account: String) -> OSStatus {
        let data = Data(string.utf8)
        return save(data, service: service, account: account)
    }
    
    func readString(service: String, account: String) -> String? {
        guard let data = read(service: service, account: account) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
