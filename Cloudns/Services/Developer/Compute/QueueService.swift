import Foundation

protocol QueueServiceProtocol: Sendable {
    func listQueues(accountId: String) async throws -> [CFQueue]
    func getQueue(accountId: String, queueId: String) async throws -> CFQueue
    func createQueue(accountId: String, name: String) async throws -> CFQueue
    func deleteQueue(accountId: String, queueId: String) async throws
    func purgeQueue(accountId: String, queueId: String) async throws
    func updateQueue(accountId: String, queueId: String, deliveryDelay: Int?, messageRetentionPeriod: Int?, deliveryPaused: Bool?) async throws -> CFQueue
    func listQueueConsumers(accountId: String, queueId: String) async throws -> [CFQueueConsumer]
    func createQueueConsumer(accountId: String, queueId: String, consumer: CFQueueConsumerCreate) async throws -> CFQueueConsumer
    func deleteQueueConsumer(accountId: String, queueId: String, consumerId: String) async throws
}

final class QueueService: QueueServiceProtocol {
    static let shared = QueueService()

    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared

    private init() {}

    func getQueues(accountId: String) async throws -> [CFQueue] {
        try await listQueues(accountId: accountId)
    }

    func listQueues(accountId: String) async throws -> [CFQueue] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/queues")
        let (queues, _): ([CFQueue]?, ResultInfo?) = try await client.performRequest(request)
        return queues ?? []
    }

    func getQueue(accountId: String, queueId: String) async throws -> CFQueue {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/queues/\(queueId)")
        let (queue, _): (CFQueue?, ResultInfo?) = try await client.performRequest(request)
        guard let q = queue else { throw APIError.cloudflareError("Failed to fetch queue details") }
        return q
    }

    func createQueue(accountId: String, name: String) async throws -> CFQueue {
        let payload = ["queue_name": name]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/queues", method: "POST", body: data)
        let (queue, _): (CFQueue?, ResultInfo?) = try await client.performRequest(request)
        guard let q = queue else { throw APIError.cloudflareError("Failed to create queue") }
        return q
    }

    func deleteQueue(accountId: String, queueId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/queues/\(queueId)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }

    func purgeQueue(accountId: String, queueId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/queues/\(queueId)/purge", method: "POST")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }

    func updateQueue(accountId: String, queueId: String, deliveryDelay: Int?, messageRetentionPeriod: Int?, deliveryPaused: Bool?) async throws -> CFQueue {
        var payload: [String: Any] = [:]
        if let d = deliveryDelay { payload["delivery_delay"] = d }
        if let m = messageRetentionPeriod { payload["message_retention_period"] = m }
        if let p = deliveryPaused { payload["delivery_paused"] = p }
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/queues/\(queueId)", method: "PATCH", body: data)
        let (queue, _): (CFQueue?, ResultInfo?) = try await client.performRequest(request)
        guard let q = queue else { throw APIError.cloudflareError("Failed to update queue") }
        return q
    }

    func listQueueConsumers(accountId: String, queueId: String) async throws -> [CFQueueConsumer] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/queues/\(queueId)/consumers")
        let (consumers, _): ([CFQueueConsumer]?, ResultInfo?) = try await client.performRequest(request)
        return consumers ?? []
    }

    func createQueueConsumer(accountId: String, queueId: String, consumer: CFQueueConsumerCreate) async throws -> CFQueueConsumer {
        let data = try JSONEncoder().encode(consumer)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/queues/\(queueId)/consumers", method: "POST", body: data)
        let (created, _): (CFQueueConsumer?, ResultInfo?) = try await client.performRequest(request)
        guard let c = created else { throw APIError.cloudflareError("Failed to bind queue consumer") }
        return c
    }

    func deleteQueueConsumer(accountId: String, queueId: String, consumerId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/queues/\(queueId)/consumers/\(consumerId)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
}
