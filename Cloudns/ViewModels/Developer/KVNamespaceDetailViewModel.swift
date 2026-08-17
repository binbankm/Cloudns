import Foundation
import SwiftUI
import Combine

@MainActor
class KVNamespaceDetailViewModel: BaseLoadableViewModel {
    let accountId: String
    let namespace: KVNamespace
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var keys: [KVKey] = []
    @Published var selectedKey: String?
    @Published var selectedKeyValue: String?
    @Published var isValueLoading = false
    
    init(accountId: String, namespace: KVNamespace) {
        self.accountId = accountId
        self.namespace = namespace
        super.init()
    }
    
    func fetchKeys() async {
        await executeLoadingTask {
            self.keys = try await self.apiClient.getKVKeys(accountId: self.accountId, namespaceId: self.namespace.id)
        }
    }
    
    func fetchValue(key: String) async {
        isValueLoading = true
        selectedKey = key
        selectedKeyValue = nil
        do {
            self.selectedKeyValue = try await apiClient.getKVValue(accountId: accountId, namespaceId: namespace.id, key: key)
        } catch {
            self.selectedKeyValue = "Error reading value: \(error.localizedDescription)"
        }
        isValueLoading = false
    }
    
    func saveKey(key: String, value: String, ttl: Int? = nil) async throws {
        try await apiClient.saveKVValue(accountId: accountId, namespaceId: namespace.id, key: key, value: value, expirationTTL: ttl)
        await fetchKeys()
    }
    
    func deleteKey(key: String) async throws {
        try await apiClient.deleteKVKey(accountId: accountId, namespaceId: namespace.id, key: key)
        await fetchKeys()
    }
}
