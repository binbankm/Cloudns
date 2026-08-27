import Foundation

/// Cloudflare Queues 消息队列领域服务抽象协议
protocol QueueServiceProtocol: Sendable {
    func listQueues(accountId: String) async throws -> [CFQueue]
    func createQueue(accountId: String, name: String) async throws -> CFQueue
    func deleteQueue(accountId: String, queueId: String) async throws
    func purgeQueue(accountId: String, queueId: String) async throws
}

/// 统一的 Cloudflare Queues 消息队列领域服务
final class QueueService: QueueServiceProtocol {
    // MARK: - Lifecycle & Dependencies
     = QueueService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    // MARK: - Queues Management API
    (accountId: String) async throws -> [CFQueue] {
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
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func purgeQueue(accountId: String, queueId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/queues/\(queueId)/purge", method: "POST")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
}
