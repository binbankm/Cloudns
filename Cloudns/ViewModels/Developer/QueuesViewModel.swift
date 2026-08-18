import Foundation
import SwiftUI
import Combine

@MainActor
final class QueuesViewModel: BaseLoadableViewModel {
    let accountId: String
    private let queueService: QueueServiceProtocol
    
    @Published var queues: [CFQueue] = []
    @Published var searchText: String = ""
    
    init(accountId: String, queueService: QueueServiceProtocol = QueueService.shared) {
        self.accountId = accountId
        self.queueService = queueService
        super.init()
    }
    
    var filteredQueues: [CFQueue] {
        if searchText.isEmpty { return queues }
        return queues.filter { $0.queueName.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchQueues() async {
        await executeLoadingTask {
            self.queues = try await self.queueService.listQueues(accountId: self.accountId)
        }
    }
    
    func createQueue(name: String) async -> Bool {
        do {
            _ = try await queueService.createQueue(accountId: accountId, name: name)
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
            try await queueService.deleteQueue(accountId: accountId, queueId: queueId)
            ToastManager.shared.showSuccess("Queue Deleted", message: "")
            await fetchQueues()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
    
    func purgeQueue(queueId: String) async {
        do {
            try await queueService.purgeQueue(accountId: accountId, queueId: queueId)
            ToastManager.shared.showSuccess("Queue Purged", message: "All messages deleted.")
        } catch {
            ToastManager.shared.showError("Purge Failed", message: error.localizedDescription)
        }
    }
}
