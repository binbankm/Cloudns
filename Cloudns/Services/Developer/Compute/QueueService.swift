import Foundation

protocol QueueServiceProtocol: Sendable {
    func listQueues(accountId: String) async throws -> [CFQueue]
    func createQueue(accountId: String, name: String) async throws -> CFQueue
    func deleteQueue(accountId: String, queueId: String) async throws
    func purgeQueue(accountId: String, queueId: String) async throws
    func getQueueConsumers(accountId: String, queueId: String) async throws -> [QueueConsumer]
    func addQueueConsumer(accountId: String, queueId: String, scriptName: String, settings: QueueConsumerSettings?) async throws -> QueueConsumer
    func deleteQueueConsumer(accountId: String, queueId: String, scriptName: String) async throws
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
        let (_, _): (CloudflareIDResponse?, ResultInfo?) = try await client.performRequest(request)
    }

    func purgeQueue(accountId: String, queueId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/queues/\(queueId)/purge", method: "POST")
        let (_, _): (CloudflareIDResponse?, ResultInfo?) = try await client.performRequest(request)
    }

    /// Fetches consumers attached to a Queue (GET /accounts/{account_id}/queues/{queue_id}/consumers)
    func getQueueConsumers(accountId: String, queueId: String) async throws -> [QueueConsumer] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/queues/\(queueId)/consumers")
        let (consumers, _): ([QueueConsumer]?, ResultInfo?) = try await client.performRequest(request)
        return consumers ?? []
    }

    /// Attaches a Worker consumer to a Queue (POST /accounts/{account_id}/queues/{queue_id}/consumers)
    func addQueueConsumer(
        accountId: String,
        queueId: String,
        scriptName: String,
        settings: QueueConsumerSettings? = nil
    ) async throws -> QueueConsumer {
        struct ConsumerPayload: Encodable, Sendable {
            let scriptName: String
            let settings: QueueConsumerSettings?

            enum CodingKeys: String, CodingKey {
                case scriptName = "script_name"
                case settings
            }
        }
        let body = try JSONEncoder().encode(ConsumerPayload(scriptName: scriptName, settings: settings))
        let request = try factory.createAuthenticatedRequest(
            path: "accounts/\(accountId)/queues/\(queueId)/consumers",
            method: "POST",
            body: body
        )
        let (consumer, _): (QueueConsumer?, ResultInfo?) = try await client.performRequest(request)
        guard let consumer else {
            throw APIError.cloudflareError("Failed to add queue consumer.")
        }
        return consumer
    }

    /// Removes a Worker consumer from a Queue (DELETE /accounts/{account_id}/queues/{queue_id}/consumers/{script_name})
    func deleteQueueConsumer(accountId: String, queueId: String, scriptName: String) async throws {
        let request = try factory.createAuthenticatedRequest(
            path: "accounts/\(accountId)/queues/\(queueId)/consumers/\(scriptName)",
            method: "DELETE"
        )
        _ = try await client.performDataRequest(request)
    }
}
