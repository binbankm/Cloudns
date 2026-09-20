import Combine
import Foundation

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
        if searchText.isEmpty {
            return queues
        }
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
        } catch {}
    }

    func purgeQueue(queueId: String) async {
        do {
            try await queueService.purgeQueue(accountId: accountId, queueId: queueId)
        } catch {}
    }

    func bindConsumer(queueId: String, consumer: CFQueueConsumerCreate) async -> Bool {
        do {
            _ = try await queueService.createQueueConsumer(accountId: accountId, queueId: queueId, consumer: consumer)
            await fetchQueues()
            return true
        } catch {
            return false
        }
    }

    func deleteConsumer(queueId: String, consumerId: String) async -> Bool {
        do {
            try await queueService.deleteQueueConsumer(accountId: accountId, queueId: queueId, consumerId: consumerId)
            await fetchQueues()
            return true
        } catch {
            return false
        }
    }

    func updateQueueSettings(queueId: String, deliveryDelay: Int?, messageRetentionPeriod: Int?, deliveryPaused: Bool? = nil) async -> CFQueue? {
        do {
            let updated = try await queueService.updateQueue(accountId: accountId, queueId: queueId, deliveryDelay: deliveryDelay, messageRetentionPeriod: messageRetentionPeriod, deliveryPaused: deliveryPaused)
            await fetchQueues()
            return updated
        } catch {
            return nil
        }
    }

    func refreshQueue(queueId: String) async -> CFQueue? {
        do {
            let updated = try await queueService.getQueue(accountId: accountId, queueId: queueId)
            if let idx = queues.firstIndex(where: { $0.id == queueId }) {
                queues[idx] = updated
            }
            return updated
        } catch {
            return nil
        }
    }
}
