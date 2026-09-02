import Foundation

protocol AuditLogServiceProtocol: Sendable {
    func getAuditLogs(accountId: String) async throws -> [AuditLog]
}

final class AuditLogService: AuditLogServiceProtocol {
    static let shared = AuditLogService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func getAuditLogs(accountId: String) async throws -> [AuditLog] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/audit_logs")
        let (logs, _): ([AuditLog]?, ResultInfo?) = try await client.performRequest(request)
        return logs ?? []
    }
}
