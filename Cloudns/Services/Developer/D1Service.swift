import Foundation

/// Cloudflare D1 SQL 数据库领域服务抽象协议
protocol D1ServiceProtocol: Sendable {
    func getD1Databases(accountId: String) async throws -> [D1Database]
    func listD1Databases(accountId: String) async throws -> [D1Database]
    func createD1Database(accountId: String, name: String, primaryLocationHint: String?) async throws -> D1Database
    func deleteD1Database(accountId: String, databaseId: String) async throws
    func executeD1Query(accountId: String, databaseId: String, sql: String) async throws -> D1QueryResult
}

/// 统一的 Cloudflare D1 SQL 数据库领域服务
final class D1Service: D1ServiceProtocol {
    static let shared = D1Service()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func getD1Databases(accountId: String) async throws -> [D1Database] {
        try await listD1Databases(accountId: accountId)
    }
    
    func listD1Databases(accountId: String) async throws -> [D1Database] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/d1/database")
        let (databases, _): ([D1Database]?, ResultInfo?) = try await client.performRequest(request)
        return databases ?? []
    }
    
    func createD1Database(accountId: String, name: String, primaryLocationHint: String? = nil) async throws -> D1Database {
        var payload: [String: Any] = ["name": name]
        if let loc = primaryLocationHint, !loc.isEmpty { payload["primary_location_hint"] = loc }
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/d1/database", method: "POST", body: data)
        let (db, _): (D1Database?, ResultInfo?) = try await client.performRequest(request)
        guard let database = db else { throw APIError.cloudflareError("Failed to create D1 database") }
        return database
    }
    
    func deleteD1Database(accountId: String, databaseId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/d1/database/\(databaseId)", method: "DELETE")
        struct DeleteRes: Codable { let id: String? }
        let (_, _): (DeleteRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func executeD1Query(accountId: String, databaseId: String, sql: String) async throws -> D1QueryResult {
        let payload: [String: Any] = ["sql": sql]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/d1/database/\(databaseId)/query", method: "POST", body: data)
        let rawData = try await client.performDataRequest(request)
        let jsonStr = String(data: rawData, encoding: .utf8)
        
        if let jsonArray = try? JSONSerialization.jsonObject(with: rawData) as? [[String: Any]],
           let first = jsonArray.first {
            return parseD1Payload(first, sql: sql, rawJson: jsonStr)
        }
        if let jsonObj = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any] {
            if let results = jsonObj["result"] as? [[String: Any]], let first = results.first {
                return parseD1Payload(first, sql: sql, rawJson: jsonStr)
            }
            return parseD1Payload(jsonObj, sql: sql, rawJson: jsonStr)
        }
        return D1QueryResult(success: true, query: sql, durationMs: 10.0, rowsRead: 0, rowsWritten: 0, columns: [], rows: [], rawJson: jsonStr)
    }
    
    private func parseD1Payload(_ dict: [String: Any], sql: String, rawJson: String?) -> D1QueryResult {
        let success = (dict["success"] as? Bool) ?? true
        let meta = dict["meta"] as? [String: Any]
        let duration = (meta?["duration"] as? Double) ?? 10.0
        let rowsRead = (meta?["rows_read"] as? Int) ?? 0
        let rowsWritten = (meta?["rows_written"] as? Int) ?? 0
        
        var columns: [String] = []
        var rows: [[String: String]] = []
        
        if let resultsList = dict["results"] as? [[String: Any]] {
            if let firstRow = resultsList.first {
                columns = Array(firstRow.keys).sorted()
            }
            for item in resultsList {
                var rowMap: [String: String] = [:]
                for (k, v) in item {
                    if v is NSNull {
                        rowMap[k] = "NULL"
                    } else {
                        rowMap[k] = "\(v)"
                    }
                }
                rows.append(rowMap)
            }
        }
        return D1QueryResult(success: success, query: sql, durationMs: duration, rowsRead: rowsRead, rowsWritten: rowsWritten, columns: columns, rows: rows, rawJson: rawJson)
    }
}
