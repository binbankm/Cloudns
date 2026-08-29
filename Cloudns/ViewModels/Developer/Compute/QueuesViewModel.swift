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
        return queues.filter { $0.queueName.localizedStandardContains(searchText) }
    }
    
    func fetchQueues() async {
        await executeLoadingTask {
            self.queues = try await self.queueService.listQueues(accountId: self.accountId)
        }
    }
    
    func createQueue(name: String) async -> Bool {
        do {
            _ = try await queueService.createQueue(accountId: accountId, name: name)
            await fetchQueues()
            return true
        } catch {
            return false
        }
    }
    
    func deleteQueue(queueId: String) async {
        do {
            try await queueService.deleteQueue(accountId: accountId, queueId: queueId)
            await fetchQueues()
        } catch {
        }
    }
    
    func purgeQueue(queueId: String) async {
        do {
            try await queueService.purgeQueue(accountId: accountId, queueId: queueId)
        } catch {
        }
    }
}
