import Foundation

protocol AuditLogServiceProtocol: Sendable {
    func getAuditLogs(accountId: String) async throws -> [AuditLog]
    func getAuditLogs(accountId: String, page: Int, perPage: Int, since: Date?, before: Date?) async throws -> ([AuditLog], ResultInfo?)
}

extension AuditLogServiceProtocol {
    func getAuditLogs(accountId: String, page: Int = 1, perPage: Int = 50, since: Date? = nil, before: Date? = nil) async throws -> ([AuditLog], ResultInfo?) {
        try await getAuditLogs(accountId: accountId, page: page, perPage: perPage, since: since, before: before)
    }
}

final class AuditLogService: AuditLogServiceProtocol {
    static let shared = AuditLogService()

    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared

    private init() {}

    func getAuditLogs(accountId: String) async throws -> [AuditLog] {
        let (logs, _) = try await getAuditLogs(accountId: accountId, page: 1, perPage: 50, since: nil, before: nil)
        return logs
    }

    func getAuditLogs(accountId: String, page: Int, perPage: Int, since: Date?, before: Date?) async throws -> ([AuditLog], ResultInfo?) {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)"),
            URLQueryItem(name: "direction", value: "desc")
        ]
        if let s = since {
            queryItems.append(URLQueryItem(name: "since", value: DateFormatters.formatISO8601(s)))
        }
        if let b = before {
            queryItems.append(URLQueryItem(name: "before", value: DateFormatters.formatISO8601(b)))
        }
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/audit_logs", queryItems: queryItems)
        let (logs, info): ([AuditLog]?, ResultInfo?) = try await client.performRequest(request)
        return (logs ?? [], info)
    }
}
