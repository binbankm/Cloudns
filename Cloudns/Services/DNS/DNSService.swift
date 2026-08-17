import Foundation

/// 统一的 Cloudflare DNS 与 DNSSEC 领域服务
final class DNSService {
    static let shared = DNSService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    /// 获取 DNS 记录列表
    func getDNSRecords(
        zoneId: String,
        page: Int = 1,
        perPage: Int = 100,
        search: String? = nil,
        type: String? = nil,
        order: String = "name",
        direction: String = "asc"
    ) async throws -> ([DNSRecord], ResultInfo?) {
        var queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)"),
            URLQueryItem(name: "order", value: order),
            URLQueryItem(name: "direction", value: direction)
        ]
        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        if let type = type, !type.isEmpty {
            queryItems.append(URLQueryItem(name: "type", value: type))
        }
        
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/dns_records", queryItems: queryItems)
        let (records, resultInfo): ([DNSRecord]?, ResultInfo?) = try await client.performRequest(request)
        return (records ?? [], resultInfo)
    }
    
    /// 创建新的 DNS 记录 (通过 DNSRecordPayload)
    func createDNSRecord(zoneId: String, payload: DNSRecordPayload) async throws -> DNSRecord {
        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/dns_records", method: "POST", body: data)
        let (newRecord, _): (DNSRecord?, ResultInfo?) = try await client.performRequest(request)
        guard let record = newRecord else {
            throw APIError.cloudflareError("Failed to create DNS record.")
        }
        return record
    }
    
    /// 创建新的 DNS 记录 (通过 DNSRecord)
    func createDNSRecord(zoneId: String, record: DNSRecord) async throws -> DNSRecord {
        let encoder = JSONEncoder()
        let data = try encoder.encode(record)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/dns_records", method: "POST", body: data)
        let (newRecord, _): (DNSRecord?, ResultInfo?) = try await client.performRequest(request)
        guard let record = newRecord else {
            throw APIError.cloudflareError("Failed to create DNS record.")
        }
        return record
    }
    
    /// 更新已有的 DNS 记录 (通过 DNSRecordPayload)
    func updateDNSRecord(zoneId: String, recordId: String, payload: DNSRecordPayload) async throws -> DNSRecord {
        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/dns_records/\(recordId)", method: "PUT", body: data)
        let (updated, _): (DNSRecord?, ResultInfo?) = try await client.performRequest(request)
        guard let record = updated else {
            throw APIError.cloudflareError("Failed to update DNS record.")
        }
        return record
    }
    
    /// 更新已有的 DNS 记录 (通过 DNSRecord)
    func updateDNSRecord(zoneId: String, recordId: String, record: DNSRecord) async throws -> DNSRecord {
        let encoder = JSONEncoder()
        let data = try encoder.encode(record)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/dns_records/\(recordId)", method: "PUT", body: data)
        let (updated, _): (DNSRecord?, ResultInfo?) = try await client.performRequest(request)
        guard let record = updated else {
            throw APIError.cloudflareError("Failed to update DNS record.")
        }
        return record
    }
    
    /// 删除 DNS 记录
    func deleteDNSRecord(zoneId: String, recordId: String) async throws -> String {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/dns_records/\(recordId)", method: "DELETE")
        struct DeleteResult: Codable { let id: String }
        let (res, _): (DeleteResult?, ResultInfo?) = try await client.performRequest(request)
        return res?.id ?? recordId
    }
    
    /// 批量删除 DNS 记录
    func batchDNSRecords(zoneId: String, deletes: [String]) async throws {
        let payload: [String: Any] = ["deletes": deletes.map { ["id": $0] }]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/dns_records/batch", method: "POST", body: data)
        struct BatchRes: Codable { let id: String? }
        let (_, _): (BatchRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    /// 导出 BIND 格式的 DNS 记录
    func exportDNSRecords(zoneId: String) async throws -> URL {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/dns_records/export", contentType: "text/plain")
        let data = try await client.performDataRequest(request)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(zoneId)-dns-records.txt")
        try data.write(to: tempURL)
        return tempURL
    }
    
    /// 导入 BIND 格式的 DNS 记录
    func importDNSRecords(zoneId: String, fileURL: URL) async throws {
        let fileData = try Data(contentsOf: fileURL)
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"zone.txt\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: text/plain\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        let request = try factory.createAuthenticatedRequest(
            path: "zones/\(zoneId)/dns_records/import",
            method: "POST",
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
        struct ImportRes: Codable { let recursive_records: Int? }
        let (_, _): (ImportRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    /// 获取 DNSSEC 详情
    func getDNSSEC(zoneId: String) async throws -> DNSSEC {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/dnssec")
        let (dnssec, _): (DNSSEC?, ResultInfo?) = try await client.performRequest(request)
        guard let dnssec = dnssec else {
            throw APIError.cloudflareError("DNSSEC details not found.")
        }
        return dnssec
    }
    
    /// 更新 DNSSEC 状态 (active / disabled)
    func updateDNSSEC(zoneId: String, status: String) async throws -> DNSSEC {
        let payload = ["status": status]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/dnssec", method: "PATCH", body: data)
        let (dnssec, _): (DNSSEC?, ResultInfo?) = try await client.performRequest(request)
        guard let dnssec = dnssec else {
            throw APIError.cloudflareError("Failed to update DNSSEC status.")
        }
        return dnssec
    }
}
