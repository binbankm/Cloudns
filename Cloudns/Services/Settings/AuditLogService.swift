import Foundation

/// Cloudflare 账户审计日志领域服务协议
protocol AuditLogServiceProtocol: Sendable {
    func getAuditLogs(accountId: String) async throws -> [AuditLog]
}

/// 统一的 Cloudflare 账户审计日志领域服务
final class AuditLogService: AuditLogServiceProtocol {
    static let shared = AuditLogService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    /// 获取指定账户的审计日志
    func getAuditLogs(accountId: String) async throws -> [AuditLog] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/audit_logs")
        let (logs, _): ([AuditLog]?, ResultInfo?) = try await client.performRequest(request)
        return logs ?? []
    }
}
