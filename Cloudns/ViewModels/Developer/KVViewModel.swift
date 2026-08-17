import Foundation
import SwiftUI
import Combine

@MainActor
class KVViewModel: BaseLoadableViewModel {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var namespaces: [KVNamespace] = []
    @Published var d1Databases: [D1Database] = []
    @Published var selectedSegment = 0 // 0: KV, 1: D1
    
    @Published var keys: [KVKey] = []
    @Published var selectedKey: String?
    @Published var selectedKeyValue: String?
    @Published var isValueLoading = false
    
    init(accountId: String) {
        self.accountId = accountId
        super.init()
    }
    
    func fetchData() async {
        await executeLoadingTask {
            async let fetchKV = self.apiClient.getKVNamespaces(accountId: self.accountId)
            async let fetchD1 = self.apiClient.getD1Databases(accountId: self.accountId)
            
            let (k, d) = try await (fetchKV, fetchD1)
            self.namespaces = k
            self.d1Databases = d
        }
    }

    func createNamespace(title: String) async throws {
        _ = try await apiClient.createKVNamespace(accountId: accountId, title: title)
        await fetchData()
    }

    func deleteNamespace(namespaceId: String) async throws {
        try await apiClient.deleteKVNamespace(accountId: accountId, namespaceId: namespaceId)
        await fetchData()
    }

    func createDatabase(name: String, locationHint: String? = nil) async throws {
        _ = try await apiClient.createD1Database(accountId: accountId, name: name, primaryLocationHint: locationHint)
        await fetchData()
    }

    func deleteDatabase(databaseId: String) async throws {
        try await apiClient.deleteD1Database(accountId: accountId, databaseId: databaseId)
        await fetchData()
    }
    
    func fetchKeys(for namespaceId: String) async {
        isLoading = true
        do {
            self.keys = try await apiClient.getKVKeys(accountId: accountId, namespaceId: namespaceId)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func fetchValue(namespaceId: String, key: String) async {
        isValueLoading = true
        selectedKey = key
        selectedKeyValue = nil
        do {
            self.selectedKeyValue = try await apiClient.getKVValue(accountId: accountId, namespaceId: namespaceId, key: key)
        } catch {
            self.selectedKeyValue = "Error reading value: \(error.localizedDescription)"
        }
        isValueLoading = false
    }
    
    func saveKey(namespaceId: String, key: String, value: String, ttl: Int? = nil) async throws {
        try await apiClient.saveKVValue(accountId: accountId, namespaceId: namespaceId, key: key, value: value, expirationTTL: ttl)
        await fetchKeys(for: namespaceId)
    }
    
    func deleteKey(namespaceId: String, key: String) async throws {
        try await apiClient.deleteKVKey(accountId: accountId, namespaceId: namespaceId, key: key)
        await fetchKeys(for: namespaceId)
    }
}
