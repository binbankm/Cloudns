import Foundation
import SwiftUI
import Combine

@MainActor
class KVViewModel: BaseLoadableViewModel {
    let accountId: String
    private let kvService: KVServiceProtocol
    private let d1Service: D1ServiceProtocol
    
    @Published var namespaces: [KVNamespace] = []
    @Published var d1Databases: [D1Database] = []
    @Published var selectedSegment = 0 // 0: KV, 1: D1
    
    @Published var keys: [KVKey] = []
    @Published var selectedKey: String?
    @Published var selectedKeyValue: String?
    @Published var isValueLoading = false
    
    init(
        accountId: String,
        kvService: KVServiceProtocol = KVService.shared,
        d1Service: D1ServiceProtocol = D1Service.shared
    ) {
        self.accountId = accountId
        self.kvService = kvService
        self.d1Service = d1Service
        super.init()
    }
    
    func fetchData() async {
        let kvKey = SWRCacheStore.accountScopedKey("kv_namespaces_\(accountId)")
        let d1Key = SWRCacheStore.accountScopedKey("d1_databases_\(accountId)")
        
        // 1. [SWR Stale Cache] 优先从本地缓存秒级直出
        if !hasFetchedData {
            if let cachedKV = await SWRCacheStore.shared.get(forKey: kvKey, as: [KVNamespace].self), !cachedKV.isEmpty {
                self.namespaces = cachedKV
                self.hasFetchedData = true
            }
            if let cachedD1 = await SWRCacheStore.shared.get(forKey: d1Key, as: [D1Database].self), !cachedD1.isEmpty {
                self.d1Databases = cachedD1
                self.hasFetchedData = true
            }
        }
        
        await executeLoadingTask {
            async let fetchKV = self.kvService.listKVNamespaces(accountId: self.accountId)
            async let fetchD1 = self.d1Service.listD1Databases(accountId: self.accountId)
            
            let (k, d) = try await (fetchKV, fetchD1)
            self.namespaces = k
            self.d1Databases = d
            
            // 2. [SWR Update Cache] 存入最新数据
            await SWRCacheStore.shared.set(k, forKey: kvKey)
            await SWRCacheStore.shared.set(d, forKey: d1Key)
        }
    }

    func createNamespace(title: String) async throws {
        _ = try await kvService.createKVNamespace(accountId: accountId, title: title)
        await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("developer_hub_overview_snapshot"))
        await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("dashboard_overview_snapshot"))
        NotificationCenter.default.post(name: .developerResourceMutated, object: nil)
        await fetchData()
    }

    func deleteNamespace(namespaceId: String) async throws {
        try await kvService.deleteKVNamespace(accountId: accountId, namespaceId: namespaceId)
        await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("developer_hub_overview_snapshot"))
        await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("dashboard_overview_snapshot"))
        NotificationCenter.default.post(name: .developerResourceMutated, object: nil)
        await fetchData()
    }

    func createDatabase(name: String, locationHint: String? = nil) async throws {
        _ = try await d1Service.createD1Database(accountId: accountId, name: name, primaryLocationHint: locationHint)
        await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("developer_hub_overview_snapshot"))
        await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("dashboard_overview_snapshot"))
        NotificationCenter.default.post(name: .developerResourceMutated, object: nil)
        await fetchData()
    }

    func deleteDatabase(databaseId: String) async throws {
        try await d1Service.deleteD1Database(accountId: accountId, databaseId: databaseId)
        await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("developer_hub_overview_snapshot"))
        await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("dashboard_overview_snapshot"))
        NotificationCenter.default.post(name: .developerResourceMutated, object: nil)
        await fetchData()
    }
    
    func fetchKeys(for namespaceId: String) async {
        isLoading = true
        do {
            self.keys = try await kvService.listKVKeys(accountId: accountId, namespaceId: namespaceId, prefix: nil, limit: 100)
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
            self.selectedKeyValue = try await kvService.getKVValue(accountId: accountId, namespaceId: namespaceId, key: key)
        } catch {
            self.selectedKeyValue = "Error reading value: \(error.localizedDescription)"
        }
        isValueLoading = false
    }
    
    func saveKey(namespaceId: String, key: String, value: String, ttl: Int? = nil) async throws {
        try await kvService.saveKVValue(accountId: accountId, namespaceId: namespaceId, key: key, value: value, expirationTTL: ttl)
        await fetchKeys(for: namespaceId)
    }
    
    func deleteKey(namespaceId: String, key: String) async throws {
        try await kvService.deleteKVKey(accountId: accountId, namespaceId: namespaceId, key: key)
        await fetchKeys(for: namespaceId)
    }
}
