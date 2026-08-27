import Foundation
import SwiftUI
import Combine

@MainActor
final class QueuesViewModel: BaseLoadableViewModel {
    // MARK: - Private Properties
    let accountId: String
    private let queueService: QueueServiceProtocol
    
    // MARK: - Published Properties
    @Published var queues: [CFQueue] = []
    @Published var searchText: String = ""
    
    // MARK: - Lifecycle / Init
    init(accountId: String, queueService: QueueServiceProtocol = QueueService.shared) {
        self.accountId = accountId
        self.queueService = queueService
        super.init()
    }
    
    var filteredQueues: [CFQueue] {
        if searchText.isEmpty { return queues }
        return queues.filter { $0.queueName.localizedStandardContains(searchText) }
    }
    
    // MARK: - Public Methods
    func fetchQueues() async {
        await executeLoadingTask {
            self.queues = try await self.queueService.listQueues(accountId: self.accountId)
        }
    }
    
    func createQueue(name: String) async -> Bool {
        do {
            _ = try await queueService.createQueue(accountId: accountId, name: name)
            CloudnsToastManager.shared.showSuccess("Queue Created", message: name)
            await fetchQueues()
            return true
        } catch {
            CloudnsToastManager.shared.showError("Create Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteQueue(queueId: String) async {
        do {
            try await queueService.deleteQueue(accountId: accountId, queueId: queueId)
            CloudnsToastManager.shared.showSuccess("Queue Deleted")
            await fetchQueues()
        } catch {
            CloudnsToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
    
    func purgeQueue(queueId: String) async {
        do {
            try await queueService.purgeQueue(accountId: accountId, queueId: queueId)
            CloudnsToastManager.shared.showSuccess("Queue Purged", message: "All messages deleted.")
        } catch {
            CloudnsToastManager.shared.showError("Purge Failed", message: error.localizedDescription)
        }
    }
}
