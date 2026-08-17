import Foundation
import SwiftUI
import Combine

@MainActor
class R2ViewModel: BaseLoadableViewModel {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var buckets: [R2Bucket] = []
    @Published var searchText = ""
    
    init(accountId: String) {
        self.accountId = accountId
        super.init()
    }
    
    var filteredBuckets: [R2Bucket] {
        if searchText.isEmpty { return buckets }
        return buckets.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchBuckets() async {
        await executeLoadingTask {
            self.buckets = try await self.apiClient.getR2Buckets(accountId: self.accountId)
        }
    }

    func createBucket(name: String, locationHint: String? = nil) async throws {
        _ = try await apiClient.createR2Bucket(accountId: accountId, name: name, locationHint: locationHint)
        await fetchBuckets()
    }

    func deleteBucket(bucketName: String) async throws {
        try await apiClient.deleteR2Bucket(accountId: accountId, bucketName: bucketName)
        await fetchBuckets()
    }
}
