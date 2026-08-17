import Foundation
import SwiftUI
import Combine

@MainActor
class R2BucketDetailViewModel: BaseLoadableViewModel {
    let accountId: String
    let bucket: R2Bucket
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var objects: [R2Object] = []
    @Published var searchText = ""
    
    init(accountId: String, bucket: R2Bucket) {
        self.accountId = accountId
        self.bucket = bucket
        super.init()
    }
    
    var filteredObjects: [R2Object] {
        if searchText.isEmpty { return objects }
        return objects.filter { $0.key.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchObjects() async {
        await executeLoadingTask {
            self.objects = try await self.apiClient.getR2Objects(accountId: self.accountId, bucketName: self.bucket.name)
        }
    }

    func deleteObject(key: String) async throws {
        try await apiClient.deleteR2Object(accountId: accountId, bucketName: bucket.name, objectKey: key)
        await fetchObjects()
    }

    func uploadObject(key: String, data: Data, contentType: String = "application/octet-stream") async throws {
        try await apiClient.putR2Object(accountId: accountId, bucketName: bucket.name, objectKey: key, data: data, contentType: contentType)
        await fetchObjects()
    }
}
