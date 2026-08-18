import Foundation

/// Cloudflare R2 对象存储领域服务抽象协议
protocol R2ServiceProtocol: Sendable {
    func getR2Buckets(accountId: String) async throws -> [R2Bucket]
    func listR2Buckets(accountId: String) async throws -> [R2Bucket]
    func createR2Bucket(accountId: String, name: String, locationHint: String?) async throws -> R2Bucket
    func deleteR2Bucket(accountId: String, bucketName: String) async throws
    func getR2Objects(accountId: String, bucketName: String) async throws -> [R2Object]
    func listR2Objects(accountId: String, bucketName: String, prefix: String?, cursor: String?) async throws -> (objects: [R2Object], cursor: String?, isTruncated: Bool)
    func putR2Object(accountId: String, bucketName: String, objectKey: String, data: Data, contentType: String) async throws
    func uploadR2ObjectFromFile(accountId: String, bucketName: String, objectKey: String, fileURL: URL, contentType: String) async throws
    func deleteR2Object(accountId: String, bucketName: String, objectKey: String) async throws
    func getR2ManagedDomain(accountId: String, bucketName: String) async throws -> R2ManagedDomain
    func setR2ManagedDomain(accountId: String, bucketName: String, enabled: Bool) async throws
    func getR2CustomDomains(accountId: String, bucketName: String) async throws -> [R2CustomDomain]
    func deleteR2CustomDomain(accountId: String, bucketName: String, domain: String) async throws
    func getR2CORS(accountId: String, bucketName: String) async throws -> [R2CORSRule]
    func putR2CORS(accountId: String, bucketName: String, rules: [R2CORSRule]) async throws
    func deleteR2CORS(accountId: String, bucketName: String) async throws
}

/// 统一的 Cloudflare R2 对象存储领域服务
final class R2Service: R2ServiceProtocol {
    static let shared = R2Service()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private static let safeKeyCharSet: CharacterSet = {
        var set = CharacterSet.urlPathAllowed
        set.remove(charactersIn: "/?#[]@!$&'()*+,;=")
        return set
    }()
    
    private init() {}
    
    func getR2Buckets(accountId: String) async throws -> [R2Bucket] {
        try await listR2Buckets(accountId: accountId)
    }
    
    func listR2Buckets(accountId: String) async throws -> [R2Bucket] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/r2/buckets")
        struct R2BucketsResponse: Codable {
            let buckets: [R2Bucket]?
        }
        let (res, _): (R2BucketsResponse?, ResultInfo?) = try await client.performRequest(request)
        return res?.buckets ?? []
    }
    
    func createR2Bucket(accountId: String, name: String, locationHint: String? = nil) async throws -> R2Bucket {
        var payload: [String: Any] = ["name": name]
        if let loc = locationHint, !loc.isEmpty { payload["locationHint"] = loc }
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/r2/buckets", method: "POST", body: data)
        let (bucket, _): (R2Bucket?, ResultInfo?) = try await client.performRequest(request)
        guard let b = bucket else { throw APIError.cloudflareError("Failed to create R2 bucket") }
        return b
    }
    
    func deleteR2Bucket(accountId: String, bucketName: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/r2/buckets/\(bucketName)", method: "DELETE")
        struct DeleteRes: Codable { let id: String? }
        let (_, _): (DeleteRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func getR2Objects(accountId: String, bucketName: String) async throws -> [R2Object] {
        let res = try await listR2Objects(accountId: accountId, bucketName: bucketName)
        return res.objects
    }
    
    func listR2Objects(accountId: String, bucketName: String, prefix: String? = nil, cursor: String? = nil) async throws -> (objects: [R2Object], cursor: String?, isTruncated: Bool) {
        var queryItems: [URLQueryItem] = []
        if let p = prefix, !p.isEmpty {
            queryItems.append(URLQueryItem(name: "prefix", value: p))
        }
        if let c = cursor, !c.isEmpty {
            queryItems.append(URLQueryItem(name: "cursor", value: c))
        }
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/r2/buckets/\(bucketName)/objects", queryItems: queryItems)
        struct R2ObjectsListRes: Codable {
            let objects: [R2Object]?
            let cursor: String?
            let truncated: Bool?
        }
        let (res, _): (R2ObjectsListRes?, ResultInfo?) = try await client.performRequest(request)
        return (res?.objects ?? [], res?.cursor, res?.truncated ?? false)
    }
    
    func putR2Object(accountId: String, bucketName: String, objectKey: String, data: Data, contentType: String = "application/octet-stream") async throws {
        let encodedKey = objectKey.addingPercentEncoding(withAllowedCharacters: Self.safeKeyCharSet) ?? objectKey
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/r2/buckets/\(bucketName)/objects/\(encodedKey)", method: "PUT", body: data, contentType: contentType)
        struct Res: Codable { let key: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func uploadR2ObjectFromFile(accountId: String, bucketName: String, objectKey: String, fileURL: URL, contentType: String = "application/octet-stream") async throws {
        let encodedKey = objectKey.addingPercentEncoding(withAllowedCharacters: Self.safeKeyCharSet) ?? objectKey
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/r2/buckets/\(bucketName)/objects/\(encodedKey)", method: "PUT", contentType: contentType)
        let (_, response) = try await URLSession.shared.upload(for: request, fromFile: fileURL)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }
    }
    
    func deleteR2Object(accountId: String, bucketName: String, objectKey: String) async throws {
        let encodedKey = objectKey.addingPercentEncoding(withAllowedCharacters: Self.safeKeyCharSet) ?? objectKey
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/r2/buckets/\(bucketName)/objects/\(encodedKey)", method: "DELETE")
        struct Res: Codable { let key: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func getR2ManagedDomain(accountId: String, bucketName: String) async throws -> R2ManagedDomain {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/r2/buckets/\(bucketName)/domains/managed")
        let (dom, _): (R2ManagedDomain?, ResultInfo?) = try await client.performRequest(request)
        return dom ?? R2ManagedDomain(domain: "\(bucketName).r2.dev", enabled: false)
    }
    
    func setR2ManagedDomain(accountId: String, bucketName: String, enabled: Bool) async throws {
        let payload = ["enabled": enabled]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/r2/buckets/\(bucketName)/domains/managed", method: "PUT", body: data)
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func getR2CustomDomains(accountId: String, bucketName: String) async throws -> [R2CustomDomain] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/r2/buckets/\(bucketName)/domains/custom")
        struct R2CustomDomainsRes: Codable {
            let domains: [R2CustomDomain]?
        }
        if let (wrapped, _): (R2CustomDomainsRes?, ResultInfo?) = try? await client.performRequest(request), let domains = wrapped?.domains {
            return domains
        }
        let (doms, _): ([R2CustomDomain]?, ResultInfo?) = try await client.performRequest(request)
        return doms ?? []
    }
    
    func deleteR2CustomDomain(accountId: String, bucketName: String, domain: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/r2/buckets/\(bucketName)/domains/custom/\(domain)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func getR2CORS(accountId: String, bucketName: String) async throws -> [R2CORSRule] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/r2/buckets/\(bucketName)/cors")
        struct CORSResponse: Codable {
            let rules: [R2CORSRule]?
        }
        let (res, _): (CORSResponse?, ResultInfo?) = try await client.performRequest(request)
        return res?.rules ?? []
    }
    
    func putR2CORS(accountId: String, bucketName: String, rules: [R2CORSRule]) async throws {
        let data = try JSONEncoder().encode(["rules": rules])
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/r2/buckets/\(bucketName)/cors", method: "PUT", body: data)
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func deleteR2CORS(accountId: String, bucketName: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/r2/buckets/\(bucketName)/cors", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
}
