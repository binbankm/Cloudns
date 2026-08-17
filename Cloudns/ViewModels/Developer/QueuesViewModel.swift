import Foundation
import SwiftUI
import Combine

@MainActor
final class QueuesViewModel: BaseLoadableViewModel {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var queues: [CFQueue] = []
    @Published var searchText: String = ""
    
    init(accountId: String) {
        self.accountId = accountId
        super.init()
    }
    
    var filteredQueues: [CFQueue] {
        if searchText.isEmpty { return queues }
        return queues.filter { $0.queueName.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchQueues() async {
        await executeLoadingTask {
            self.queues = try await self.apiClient.listQueues(accountId: self.accountId)
        }
    }
    
    func createQueue(name: String) async -> Bool {
        do {
            _ = try await apiClient.createQueue(accountId: accountId, name: name)
            ToastManager.shared.showSuccess("Queue Created", message: name)
            await fetchQueues()
            return true
        } catch {
            ToastManager.shared.showError("Create Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteQueue(queueId: String) async {
        do {
            try await apiClient.deleteQueue(accountId: accountId, queueId: queueId)
            ToastManager.shared.showSuccess("Queue Deleted", message: "")
            await fetchQueues()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
    
    func purgeQueue(queueId: String) async {
        do {
            try await apiClient.purgeQueue(accountId: accountId, queueId: queueId)
            ToastManager.shared.showSuccess("Queue Purged", message: "All messages deleted.")
        } catch {
            ToastManager.shared.showError("Purge Failed", message: error.localizedDescription)
        }
    }
}
