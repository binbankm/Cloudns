import Foundation
import SwiftUI
import Combine

@MainActor
class KVNamespaceDetailViewModel: BaseLoadableViewModel {
    let accountId: String
    let namespace: KVNamespace
    private let kvService: KVServiceProtocol
    
    @Published var keys: [KVKey] = []
    @Published var selectedKey: String?
    @Published var selectedKeyValue: String?
    @Published var isValueLoading = false
    
    init(accountId: String, namespace: KVNamespace, kvService: KVServiceProtocol = KVService.shared) {
        self.accountId = accountId
        self.namespace = namespace
        self.kvService = kvService
        super.init()
    }
    
    func fetchKeys() async {
        await executeLoadingTask {
            self.keys = try await self.kvService.getKVKeys(accountId: self.accountId, namespaceId: self.namespace.id)
        }
    }
    
    func fetchValue(key: String) async {
        isValueLoading = true
        selectedKey = key
        selectedKeyValue = nil
        do {
            self.selectedKeyValue = try await kvService.getKVValue(accountId: accountId, namespaceId: namespace.id, key: key)
        } catch {
            self.selectedKeyValue = "Error reading value: \(error.localizedDescription)"
        }
        isValueLoading = false
    }
    
    func saveKey(key: String, value: String, ttl: Int? = nil) async throws {
        try await kvService.saveKVValue(accountId: accountId, namespaceId: namespace.id, key: key, value: value, expirationTTL: ttl)
        await fetchKeys()
    }
    
    func deleteKey(key: String) async throws {
        try await kvService.deleteKVKey(accountId: accountId, namespaceId: namespace.id, key: key)
        await fetchKeys()
    }
}
