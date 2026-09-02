import Foundation
import SwiftUI
import Combine

@MainActor
final class R2ViewModel: BaseLoadableViewModel {
    let accountId: String
    private let r2Service: R2ServiceProtocol
    
    @Published var buckets: [R2Bucket] = []
    @Published var searchText = ""
    
    init(accountId: String, r2Service: R2ServiceProtocol = R2Service.shared) {
        self.accountId = accountId
        self.r2Service = r2Service
        super.init()
    }
    
    var filteredBuckets: [R2Bucket] {
        if searchText.isEmpty { return buckets }
        return buckets.filter { $0.name.localizedStandardContains(searchText) }
    }
    
    func fetchBuckets() async {
        let scopedKey = SWRCacheStore.accountScopedKey("r2_buckets_\(accountId)")
        
        if !hasFetchedData {
            if let cached = await SWRCacheStore.shared.get(forKey: scopedKey, as: [R2Bucket].self), !cached.isEmpty {
                self.buckets = cached
                self.hasFetchedData = true
            }
        }
        
        await executeLoadingTask {
            let latestBuckets = try await self.r2Service.listR2Buckets(accountId: self.accountId)
            self.buckets = latestBuckets
            await SWRCacheStore.shared.set(latestBuckets, forKey: scopedKey)
        }
    }

    func createBucket(name: String, locationHint: String? = nil) async throws {
        _ = try await r2Service.createR2Bucket(accountId: accountId, name: name, locationHint: locationHint)
        await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("developer_hub_overview_snapshot"))
        await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("dashboard_overview_snapshot"))
        NotificationCenter.default.post(name: .developerResourceMutated, object: nil)
        await fetchBuckets()
    }

    func deleteBucket(bucketName: String) async throws {
        try await r2Service.deleteR2Bucket(accountId: accountId, bucketName: bucketName)
        await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("developer_hub_overview_snapshot"))
        await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("dashboard_overview_snapshot"))
        NotificationCenter.default.post(name: .developerResourceMutated, object: nil)
        await fetchBuckets()
    }
}
