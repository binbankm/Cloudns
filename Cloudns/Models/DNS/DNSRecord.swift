import Foundation

struct DNSRecord: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let type: String
    let name: String
    let content: String?
    let proxiable: Bool?
    var proxied: Bool?
    let ttl: Int
    let locked: Bool?
    let zoneId: String?
    let zoneName: String?
    let modifiedOn: String?
    let createdOn: String?
    let priority: Int?
    let comment: String?
    let tags: [String]?
    let data: DNSRecordData?

    init(
        id: String,
        type: String,
        name: String,
        content: String?,
        proxiable: Bool? = nil,
        proxied: Bool? = nil,
        ttl: Int = 1,
        locked: Bool? = nil,
        zoneId: String? = nil,
        zoneName: String? = nil,
        modifiedOn: String? = nil,
        createdOn: String? = nil,
        priority: Int? = nil,
        comment: String? = nil,
        tags: [String]? = nil,
        data: DNSRecordData? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.content = content
        self.proxiable = proxiable
        self.proxied = proxied
        self.ttl = ttl
        self.locked = locked
        self.zoneId = zoneId
        self.zoneName = zoneName
        self.modifiedOn = modifiedOn
        self.createdOn = createdOn
        self.priority = priority
        self.comment = comment
        self.tags = tags
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case id, type, name, content, proxiable, proxied, ttl, locked, priority, comment, tags, data
        case zoneId = "zone_id"
        case zoneName = "zone_name"
        case modifiedOn = "modified_on"
        case createdOn = "created_on"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "A"
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        content = try container.decodeIfPresent(String.self, forKey: .content)
        proxiable = try container.decodeIfPresent(Bool.self, forKey: .proxiable)
        proxied = try container.decodeIfPresent(Bool.self, forKey: .proxied)
        ttl = try container.decodeIfPresent(Int.self, forKey: .ttl) ?? 1
        locked = try container.decodeIfPresent(Bool.self, forKey: .locked)
        zoneId = try container.decodeIfPresent(String.self, forKey: .zoneId)
        zoneName = try container.decodeIfPresent(String.self, forKey: .zoneName)
        modifiedOn = try container.decodeIfPresent(String.self, forKey: .modifiedOn)
        createdOn = try container.decodeIfPresent(String.self, forKey: .createdOn)
        priority = try container.decodeIfPresent(Int.self, forKey: .priority)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        data = try container.decodeIfPresent(DNSRecordData.self, forKey: .data)
    }
}

// MARK: - DNS Record Type Enum

public enum DNSRecordType: String, CaseIterable, Codable, Sendable, Identifiable {
    case a = "A"
    case aaaa = "AAAA"
    case cname = "CNAME"
    case txt = "TXT"
    case mx = "MX"
    case ns = "NS"
    case srv = "SRV"
    case caa = "CAA"
    case https = "HTTPS"
    case svcb = "SVCB"
    case ptr = "PTR"
    case spf = "SPF"
    case loc = "LOC"

    public var id: String { rawValue }

    /// Returns true if this record type supports Cloudflare CDN proxying
    public var isProxiable: Bool {
        switch self {
        case .a, .aaaa, .cname:
            return true
        default:
            return false
        }
    }
}

// MARK: - DNS Record Data (RFC 9460 & CAA & SRV)

public struct DNSRecordData: Codable, Equatable, Sendable {
    // SRV
    public var service: String?
    public var proto: String?
    public var name: String?
    public var priority: Int?
    public var weight: Int?
    public var port: Int?
    public var target: String?

    // CAA
    public var flags: Int?
    public var tag: String?
    public var value: String?

    // HTTPS / SVCB (RFC 9460)
    public var svcPriority: Int?
    public var targetName: String?
    public var svcParams: String?

    public init(
        service: String? = nil,
        proto: String? = nil,
        name: String? = nil,
        priority: Int? = nil,
        weight: Int? = nil,
        port: Int? = nil,
        target: String? = nil,
        flags: Int? = nil,
        tag: String? = nil,
        value: String? = nil,
        svcPriority: Int? = nil,
        targetName: String? = nil,
        svcParams: String? = nil
    ) {
        self.service = service
        self.proto = proto
        self.name = name
        self.priority = priority
        self.weight = weight
        self.port = port
        self.target = target
        self.flags = flags
        self.tag = tag
        self.value = value
        self.svcPriority = svcPriority
        self.targetName = targetName
        self.svcParams = svcParams
    }
}

// MARK: - Payloads

public struct DNSRecordPayload: Codable, Sendable {
    public let type: String
    public let name: String
    public let content: String?
    public let ttl: Int
    public let proxied: Bool?
    public let priority: Int?
    public let comment: String?
    public let tags: [String]?
    public let data: DNSRecordData?

    public init(
        type: String,
        name: String,
        content: String?,
        ttl: Int = 1,
        proxied: Bool? = nil,
        priority: Int? = nil,
        comment: String? = nil,
        tags: [String]? = nil,
        data: DNSRecordData? = nil
    ) {
        self.type = type
        self.name = name
        self.content = content
        self.ttl = ttl
        self.proxied = proxied
        self.priority = priority
        self.comment = comment
        self.tags = tags
        self.data = data
    }
}

/// Lightweight payload for official Cloudflare PATCH /zones/{id}/dns_records/{id}
public struct DNSRecordPatchPayload: Codable, Sendable {
    public var name: String?
    public var type: String?
    public var content: String?
    public var ttl: Int?
    public var proxied: Bool?
    public var comment: String?
    public var tags: [String]?
    public var priority: Int?
    public var data: DNSRecordData?

    public init(
        name: String? = nil,
        type: String? = nil,
        content: String? = nil,
        ttl: Int? = nil,
        proxied: Bool? = nil,
        comment: String? = nil,
        tags: [String]? = nil,
        priority: Int? = nil,
        data: DNSRecordData? = nil
    ) {
        self.name = name
        self.type = type
        self.content = content
        self.ttl = ttl
        self.proxied = proxied
        self.comment = comment
        self.tags = tags
        self.priority = priority
        self.data = data
    }
}

public struct BatchDNSRecordDelete: Codable, Sendable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

public struct BatchDNSRecordsRequest: Codable, Sendable {
    public let deletes: [BatchDNSRecordDelete]?

    public init(deletes: [BatchDNSRecordDelete]? = nil) {
        self.deletes = deletes
    }
}
