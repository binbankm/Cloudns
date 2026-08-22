import Foundation
import SwiftUI
import Combine

@MainActor
class R2BucketDetailViewModel: BaseLoadableViewModel {
    let accountId: String
    let bucket: R2Bucket
    private let r2Service: R2ServiceProtocol
    
    @Published var objects: [R2Object] = []
    @Published var searchText = ""
    
    init(accountId: String, bucket: R2Bucket, r2Service: R2ServiceProtocol = R2Service.shared) {
        self.accountId = accountId
        self.bucket = bucket
        self.r2Service = r2Service
        super.init()
    }
    
    var filteredObjects: [R2Object] {
        if searchText.isEmpty { return objects }
        return objects.filter { $0.key.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchObjects() async {
        await executeLoadingTask {
            self.objects = try await self.r2Service.getR2Objects(accountId: self.accountId, bucketName: self.bucket.name)
        }
    }

    func deleteObject(key: String) async throws {
        try await r2Service.deleteR2Object(accountId: accountId, bucketName: bucket.name, objectKey: key)
        await fetchObjects()
    }

    func uploadObject(key: String, data: Data, contentType: String = "application/octet-stream") async throws {
        try await r2Service.putR2Object(accountId: accountId, bucketName: bucket.name, objectKey: key, data: data, contentType: contentType)
        await fetchObjects()
    }
    
    func uploadObjectFromFile(key: String, fileURL: URL, contentType: String = "application/octet-stream") async throws {
        try await r2Service.uploadR2ObjectFromFile(accountId: accountId, bucketName: bucket.name, objectKey: key, fileURL: fileURL, contentType: contentType)
        await fetchObjects()
    }
}
