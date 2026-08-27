import Foundation
import SwiftUI
import Combine

@MainActor
final class KVNamespaceDetailViewModel: BaseLoadableViewModel {
    // MARK: - Private Properties
    let accountId: String
    let namespace: KVNamespace
    private let kvService: KVServiceProtocol
    
    // MARK: - Published Properties
    @Published var keys: [KVKey] = []
    @Published var selectedKey: String?
    @Published var selectedKeyValue: String?
    @Published var isValueLoading = false
    
    // MARK: - Lifecycle / Init
    init(accountId: String, namespace: KVNamespace, kvService: KVServiceProtocol = KVService.shared) {
        self.accountId = accountId
        self.namespace = namespace
        self.kvService = kvService
        super.init()
    }
    
    // MARK: - Public Methods
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
        let exp: Int? = ttl.flatMap { $0 > 0 ? Int(Date().timeIntervalSince1970) + $0 : nil }
        let newKey = KVKey(name: key, expiration: exp)
        withAnimation {
            if let index = self.keys.firstIndex(where: { $0.name == key }) {
                self.keys[index] = newKey
            } else {
                self.keys.insert(newKey, at: 0)
            }
        }
        await fetchKeys()
    }
    
    func deleteKey(key: String) async throws {
        withAnimation {
            self.keys.removeAll { $0.name == key }
        }
        try await kvService.deleteKVKey(accountId: accountId, namespaceId: namespace.id, key: key)
        await fetchKeys()
    }
}
