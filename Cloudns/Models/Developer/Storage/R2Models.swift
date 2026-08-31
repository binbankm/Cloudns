import Foundation

// MARK: - R2 Storage Models

public struct R2Bucket: Codable, Identifiable, Equatable, Sendable {
    public var id: String { name }
    public let name: String
    public let creationDate: String?
    public let location: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case creationDate = "creation_date"
        case location
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Bucket"
        self.creationDate = try container.decodeIfPresent(String.self, forKey: .creationDate)
        self.location = try container.decodeIfPresent(String.self, forKey: .location)
    }
    
    public init(name: String, creationDate: String? = "2024-01-01T00:00:00Z", location: String? = "WNAM") {
        self.name = name
        self.creationDate = creationDate
        self.location = location
    }
    
}

public struct R2Object: Codable, Identifiable, Equatable, Sendable {
    public var id: String { key }
    public let key: String
    public let size: Int
    public let etag: String?
    public let version: String?
    public let uploaded: String?
    public let storageClass: String?
    public let httpEtag: String?
    
    enum CodingKeys: String, CodingKey {
        case key, size, etag, version, uploaded
        case storageClass = "storage_class"
        case httpEtag
    }
    
    public var formattedSize: String {
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
    
    public init(
        key: String,
        size: Int = 1048576,
        etag: String? = "d41d8cd98f00b204e9800998ecf8427e",
        version: String? = "v1",
        uploaded: String? = "2024-01-01T00:00:00Z",
        storageClass: String? = "Standard",
        httpEtag: String? = nil
    ) {
        self.key = key
        self.size = size
        self.etag = etag
        self.version = version
        self.uploaded = uploaded
        self.storageClass = storageClass
        self.httpEtag = httpEtag
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = (try? container.decode(String.self, forKey: .key)) ?? ""
        
        if let intSize = try? container.decode(Int.self, forKey: .size) {
            self.size = intSize
        } else if let dblSize = try? container.decode(Double.self, forKey: .size) {
            self.size = Int(dblSize)
        } else if let strSize = try? container.decode(String.self, forKey: .size), let parsed = Int(strSize) {
            self.size = parsed
        } else {
            self.size = 0
        }
        
        self.etag = (try? container.decodeIfPresent(String.self, forKey: .etag)) ?? (try? container.decodeIfPresent(String.self, forKey: .httpEtag))
        self.version = try? container.decodeIfPresent(String.self, forKey: .version)
        self.uploaded = try? container.decodeIfPresent(String.self, forKey: .uploaded)
        self.storageClass = (try? container.decodeIfPresent(String.self, forKey: .storageClass)) ?? "Standard"
        self.httpEtag = try? container.decodeIfPresent(String.self, forKey: .httpEtag)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(size, forKey: .size)
        try container.encodeIfPresent(etag, forKey: .etag)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encodeIfPresent(uploaded, forKey: .uploaded)
        try container.encodeIfPresent(storageClass, forKey: .storageClass)
        try container.encodeIfPresent(httpEtag, forKey: .httpEtag)
    }
    
}

public struct R2ManagedDomain: Codable, Equatable, Sendable {
    public let domain: String?
    public let enabled: Bool?
    
    public init(domain: String? = nil, enabled: Bool? = nil) {
        self.domain = domain
        self.enabled = enabled
    }
}

public struct R2CustomDomain: Codable, Identifiable, Equatable, Sendable {
    public var id: String { domain }
    public let domain: String
    public let status: String?
    public let zoneId: String?
    public let zoneName: String?
    public let enabled: Bool?
    public let minTLS: String?
    
    enum CodingKeys: String, CodingKey {
        case domain, status, enabled, minTLS
        case zoneId
        case zone_id
        case zoneName
        case zone_name
    }
    
    public init(domain: String, status: String? = "active", zoneId: String? = nil, zoneName: String? = nil, enabled: Bool? = true, minTLS: String? = nil) {
        self.domain = domain
        self.status = status
        self.zoneId = zoneId
        self.zoneName = zoneName
        self.enabled = enabled
        self.minTLS = minTLS
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.domain = (try? container.decode(String.self, forKey: .domain)) ?? ""
        self.enabled = try? container.decodeIfPresent(Bool.self, forKey: .enabled)
        self.minTLS = try? container.decodeIfPresent(String.self, forKey: .minTLS)
        self.zoneId = (try? container.decodeIfPresent(String.self, forKey: .zoneId)) ?? (try? container.decodeIfPresent(String.self, forKey: .zone_id))
        self.zoneName = (try? container.decodeIfPresent(String.self, forKey: .zoneName)) ?? (try? container.decodeIfPresent(String.self, forKey: .zone_name))
        
        if let statusStr = try? container.decode(String.self, forKey: .status) {
            self.status = statusStr
        } else if let statusObj = try? container.decode([String: String].self, forKey: .status) {
            self.status = statusObj["ownership"] ?? statusObj["ssl"] ?? "active"
        } else {
            self.status = "active"
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(domain, forKey: .domain)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(zoneId, forKey: .zoneId)
        try container.encodeIfPresent(zoneName, forKey: .zoneName)
        try container.encodeIfPresent(enabled, forKey: .enabled)
        try container.encodeIfPresent(minTLS, forKey: .minTLS)
    }
    
}

public struct R2CORSRule: Codable, Identifiable, Equatable, Sendable {
    public var id: String { customId ?? "\(allowedOrigins.joined(separator: ","))-\(allowedMethods.joined(separator: ","))" }
    public var customId: String?
    public var allowedOrigins: [String]
    public var allowedMethods: [String]
    public var allowedHeaders: [String]?
    public var exposeHeaders: [String]?
    public var maxAgeSeconds: Int?
    
    enum CodingKeys: String, CodingKey {
        case customId = "id"
        case allowed
        case exposeHeaders
        case maxAgeSeconds
    }
    
    private struct AllowedConfig: Codable, Sendable {
        let origins: [String]
        let methods: [String]
        let headers: [String]?
        
        enum CodingKeys: String, CodingKey {
            case origins, methods, headers
        }
    }
    
    public init(allowedOrigins: [String], allowedMethods: [String], allowedHeaders: [String]? = nil, exposeHeaders: [String]? = nil, maxAgeSeconds: Int? = 3600, customId: String? = nil) {
        self.allowedOrigins = allowedOrigins
        self.allowedMethods = allowedMethods
        self.allowedHeaders = allowedHeaders
        self.exposeHeaders = exposeHeaders
        self.maxAgeSeconds = maxAgeSeconds
        self.customId = customId
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.customId = try? container.decodeIfPresent(String.self, forKey: .customId)
        self.exposeHeaders = try? container.decodeIfPresent([String].self, forKey: .exposeHeaders)
        self.maxAgeSeconds = try? container.decodeIfPresent(Int.self, forKey: .maxAgeSeconds)
        
        if let allowed = try? container.decode(AllowedConfig.self, forKey: .allowed) {
            self.allowedOrigins = allowed.origins
            self.allowedMethods = allowed.methods
            self.allowedHeaders = allowed.headers
        } else if let directOrigins = try? container.decode([String].self, forKey: .allowed) {
            self.allowedOrigins = directOrigins
            self.allowedMethods = ["GET"]
            self.allowedHeaders = nil
        } else {
            self.allowedOrigins = ["*"]
            self.allowedMethods = ["GET"]
            self.allowedHeaders = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(customId, forKey: .customId)
        try container.encodeIfPresent(exposeHeaders, forKey: .exposeHeaders)
        try container.encodeIfPresent(maxAgeSeconds, forKey: .maxAgeSeconds)
        
        let allowed = AllowedConfig(origins: allowedOrigins, methods: allowedMethods, headers: allowedHeaders)
        try container.encode(allowed, forKey: .allowed)
    }
    
}
