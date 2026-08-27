import Foundation

/// Cloudflare Zone（域名）管理领域服务抽象协议
protocol ZoneServiceProtocol: Sendable {
    func getZones(page: Int, perPage: Int, name: String?, status: String?) async throws -> ([Zone], ResultInfo?)
    func getAccounts() async throws -> [Account]
    func getZoneDetails(zoneId: String) async throws -> Zone
    func createZone(name: String, accountId: String, jumpStart: Bool) async throws -> Zone
    func deleteZone(zoneId: String) async throws -> String
    func updateZoneStatus(zoneId: String, paused: Bool) async throws
    func pauseZone(zoneId: String, paused: Bool) async throws
    func purgeCache(zoneId: String) async throws
    func getAuditLogs(accountId: String) async throws -> [AuditLog]
}

extension ZoneServiceProtocol {
    func getZones(page: Int = 1, perPage: Int = 50, name: String? = nil, status: String? = nil) async throws -> ([Zone], ResultInfo?) {
        try await getZones(page: page, perPage: perPage, name: name, status: status)
    }
}

/// 统一的 Cloudflare Zone（域名）管理领域服务
final class ZoneService: ZoneServiceProtocol {
    // MARK: - Lifecycle & Dependencies
    static let shared = ZoneService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    // MARK: - Zones Query API
    /// 获取用户账号下的所有 Zone 列表
    func getZones(page: Int = 1, perPage: Int = 50, name: String? = nil, status: String? = nil) async throws -> ([Zone], ResultInfo?) {
        var queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)"),
            URLQueryItem(name: "order", value: "name"),
            URLQueryItem(name: "direction", value: "asc")
        ]
        if let name = name, !name.isEmpty {
            queryItems.append(URLQueryItem(name: "name", value: name))
        }
        if let status = status, !status.isEmpty {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        
        let request = try factory.createAuthenticatedRequest(path: "zones", queryItems: queryItems)
        let (zones, resultInfo): ([Zone]?, ResultInfo?) = try await client.performRequest(request)
        return (zones ?? [], resultInfo)
    }
    
    /// 获取账号列表
    func getAccounts() async throws -> [Account] {
        let request = try factory.createAuthenticatedRequest(path: "accounts")
        let (accounts, _): ([Account]?, ResultInfo?) = try await client.performRequest(request)
        return accounts ?? []
    }
    
    /// 获取单个 Zone 详情
    func getZoneDetails(zoneId: String) async throws -> Zone {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)")
        let (zone, _): (Zone?, ResultInfo?) = try await client.performRequest(request)
        guard let zone = zone else {
            throw APIError.cloudflareError("Zone details not found.")
        }
        return zone
    }
    
    // MARK: - Zone Mutation & Operations API
    /// 创建新的 Zone
    func createZone(name: String, accountId: String, jumpStart: Bool = false) async throws -> Zone {
        let payload: [String: Any] = [
            "name": name,
            "account": ["id": accountId],
            "jump_start": jumpStart,
            "type": "full"
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones", method: "POST", body: data)
        let (zone, _): (Zone?, ResultInfo?) = try await client.performRequest(request)
        guard let zone = zone else {
            throw APIError.cloudflareError("Failed to create Zone.")
        }
        return zone
    }
    
    /// 删除 Zone
    func deleteZone(zoneId: String) async throws -> String {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)", method: "DELETE")
        struct DeleteResult: Codable { let id: String }
        let (res, _): (DeleteResult?, ResultInfo?) = try await client.performRequest(request)
        return res?.id ?? zoneId
    }
    
    /// 暂停/恢复 Zone
    func updateZoneStatus(zoneId: String, paused: Bool) async throws {
        let payload = ["paused": paused]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)", method: "PATCH", body: data)
        let (_, _): (Zone?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func pauseZone(zoneId: String, paused: Bool) async throws {
        try await updateZoneStatus(zoneId: zoneId, paused: paused)
    }
    
    // MARK: - Cache Purge API
    /// 清除全站缓存 (Purge Everything)
    func purgeCache(zoneId: String) async throws {
        let payload = ["purge_everything": true]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/purge_cache", method: "POST", body: data)
        struct PurgeResult: Codable { let id: String? }
        let (_, _): (PurgeResult?, ResultInfo?) = try await client.performRequest(request)
    }
    
    // MARK: - Audit Logs API
    /// 获取账户审计日志 (Audit Logs)
    func getAuditLogs(accountId: String) async throws -> [AuditLog] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/audit_logs")
        let (logs, _): ([AuditLog]?, ResultInfo?) = try await client.performRequest(request)
        return logs ?? []
    }
}
