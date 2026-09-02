import Foundation

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
        let rawData = try await client.performDataRequest(request)
        
        // 1. { "result": { "buckets": […] }, "success": true }
        struct ResWithBuckets: Codable {
            let result: BucketsContainer?
            struct BucketsContainer: Codable {
                let buckets: [R2Bucket]?
            }
        }
        if let decoded = try? JSONDecoder().decode(ResWithBuckets.self, from: rawData), let buckets = decoded.result?.buckets {
            return buckets
        }
        
        // 2. { "result": [R2Bucket], "success": true }
        struct ResWithArray: Codable {
            let result: [R2Bucket]?
        }
        if let decoded = try? JSONDecoder().decode(ResWithArray.self, from: rawData), let buckets = decoded.result {
            return buckets
        }
        
        // 3. { "buckets": [R2Bucket] }
        struct DirectBuckets: Codable {
            let buckets: [R2Bucket]?
        }
        if let decoded = try? JSONDecoder().decode(DirectBuckets.self, from: rawData), let buckets = decoded.buckets {
            return buckets
        }
        
        return []
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
        let rawData = try await client.performDataRequest(request)
        
        // Strategy 1: { "result": { "objects": […], "cursor": "...", "truncated": false } }
        struct R2WrappedResult: Codable {
            let result: R2ObjectsListRes?
            struct R2ObjectsListRes: Codable {
                let objects: [R2Object]?
                let cursor: String?
                let truncated: Bool?
            }
        }
        if let wrapped = try? JSONDecoder().decode(R2WrappedResult.self, from: rawData), let res = wrapped.result {
            return (res.objects ?? [], res.cursor, res.truncated ?? false)
        }
        
        // Strategy 2: { "result": [R2Object], "success": true }
        struct R2ArrayResult: Codable {
            let result: [R2Object]?
        }
        if let arrayWrapped = try? JSONDecoder().decode(R2ArrayResult.self, from: rawData), let objects = arrayWrapped.result {
            return (objects, nil, false)
        }
        
        // Strategy 3: { "objects": [R2Object], "cursor": "...", "truncated": false }
        struct R2DirectObjects: Codable {
            let objects: [R2Object]?
            let cursor: String?
            let truncated: Bool?
        }
        if let direct = try? JSONDecoder().decode(R2DirectObjects.self, from: rawData) {
            return (direct.objects ?? [], direct.cursor, direct.truncated ?? false)
        }
        
        // Strategy 4: Direct array [R2Object]
        if let directList = try? JSONDecoder().decode([R2Object].self, from: rawData) {
            return (directList, nil, false)
        }
        
        return ([], nil, false)
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
        let (data, response) = try await URLSession.shared.upload(for: request, fromFile: fileURL)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.fromCloudflareResponse(data: data, statusCode: http.statusCode, defaultMessage: "Failed to upload file (HTTP \(http.statusCode))")
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
