import Foundation

// MARK: - R2 Storage Models

public struct R2Bucket: Codable, Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let creationDate: String?
    public let location: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case creationDate = "creation_date"
        case location
    }
    
    public init(name: String, creationDate: String? = "2024-01-01T00:00:00Z", location: String? = "WNAM") {
        self.name = name
        self.creationDate = creationDate
        self.location = location
    }
    
    public static let placeholders: [R2Bucket] = (0..<5).map { idx in
        R2Bucket(name: "assets-storage-bucket-\(idx + 1)")
    }
}

public struct R2Object: Codable, Identifiable, Equatable {
    public var id: String { key }
    public let key: String
    public let size: Int
    public let etag: String?
    public let version: String?
    public let uploaded: String?
    public let storageClass: String?
    
    enum CodingKeys: String, CodingKey {
        case key, size, etag, version, uploaded
        case storageClass = "storage_class"
    }
    
    public var formattedSize: String {
        let b = Double(size)
        if b < 1024 { return "\(size) B" }
        let kb = b / 1024.0
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024.0
        if mb < 1024 { return String(format: "%.1f MB", mb) }
        let gb = mb / 1024.0
        return String(format: "%.2f GB", gb)
    }
    
    public init(
        key: String,
        size: Int = 1048576,
        etag: String? = "d41d8cd98f00b204e9800998ecf8427e",
        version: String? = "v1",
        uploaded: String? = "2024-01-01T00:00:00Z",
        storageClass: String? = "Standard"
    ) {
        self.key = key
        self.size = size
        self.etag = etag
        self.version = version
        self.uploaded = uploaded
        self.storageClass = storageClass
    }
    
    public static let placeholders: [R2Object] = [
        R2Object(key: "assets/logo.png", size: 45000),
        R2Object(key: "backups/db-2024.sql.gz", size: 104857600),
        R2Object(key: "configs/app.json", size: 2400)
    ]
}

public struct R2ManagedDomain: Codable, Equatable {
    public let domain: String?
    public let enabled: Bool?
    
    public init(domain: String? = nil, enabled: Bool? = nil) {
        self.domain = domain
        self.enabled = enabled
    }
}

public struct R2CustomDomain: Codable, Identifiable, Equatable {
    public var id: String { domain }
    public let domain: String
    public let status: String?
    public let zoneId: String?
    public let enabled: Bool?
    
    enum CodingKeys: String, CodingKey {
        case domain, status, enabled
        case zoneId = "zone_id"
    }
    
    public init(domain: String, status: String? = "active", zoneId: String? = "zone_123", enabled: Bool? = true) {
        self.domain = domain
        self.status = status
        self.zoneId = zoneId
        self.enabled = enabled
    }
    
    public static let placeholders: [R2CustomDomain] = [
        R2CustomDomain(domain: "cdn.example.com"),
        R2CustomDomain(domain: "static.example.com")
    ]
}

public struct R2CORSRule: Codable, Identifiable, Equatable {
    public var id: String { "\(allowedOrigins.joined(separator: ","))-\(allowedMethods.joined(separator: ","))" }
    public var allowedOrigins: [String]
    public var allowedMethods: [String]
    public var allowedHeaders: [String]?
    public var exposeHeaders: [String]?
    public var maxAgeSeconds: Int?
    
    enum CodingKeys: String, CodingKey {
        case allowedOrigins = "allowed"
        case allowedMethods = "methods"
        case allowedHeaders = "headers"
        case exposeHeaders = "exposeHeaders"
        case maxAgeSeconds = "maxAgeSeconds"
    }
    
    public init(allowedOrigins: [String], allowedMethods: [String], allowedHeaders: [String]? = nil, exposeHeaders: [String]? = nil, maxAgeSeconds: Int? = 3600) {
        self.allowedOrigins = allowedOrigins
        self.allowedMethods = allowedMethods
        self.allowedHeaders = allowedHeaders
        self.exposeHeaders = exposeHeaders
        self.maxAgeSeconds = maxAgeSeconds
    }
    
    public static let placeholders: [R2CORSRule] = [
        R2CORSRule(allowedOrigins: ["*"], allowedMethods: ["GET", "HEAD"], allowedHeaders: ["*"], maxAgeSeconds: 3600)
    ]
}
