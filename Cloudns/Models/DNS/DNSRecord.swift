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
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? "A"
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.content = try container.decodeIfPresent(String.self, forKey: .content)
        self.proxiable = try container.decodeIfPresent(Bool.self, forKey: .proxiable)
        self.proxied = try container.decodeIfPresent(Bool.self, forKey: .proxied)
        self.ttl = try container.decodeIfPresent(Int.self, forKey: .ttl) ?? 1
        self.locked = try container.decodeIfPresent(Bool.self, forKey: .locked)
        self.zoneId = try container.decodeIfPresent(String.self, forKey: .zoneId)
        self.zoneName = try container.decodeIfPresent(String.self, forKey: .zoneName)
        self.modifiedOn = try container.decodeIfPresent(String.self, forKey: .modifiedOn)
        self.createdOn = try container.decodeIfPresent(String.self, forKey: .createdOn)
        self.priority = try container.decodeIfPresent(Int.self, forKey: .priority)
        self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags)
        self.data = try container.decodeIfPresent(DNSRecordData.self, forKey: .data)
    }
}

struct DNSRecordData: Codable, Equatable, Sendable {
    // SRV
    var service: String?
    var proto: String?
    var name: String?
    var priority: Int?
    var weight: Int?
    var port: Int?
    var target: String?
    
    // CAA
    var flags: Int?
    var tag: String?
    var value: String?
    
    // HTTPS / SVCB (RFC 9460)
    // Priority, target, and value / params
}

struct DNSRecordPayload: Codable, Sendable {
    let type: String
    let name: String
    let content: String?
    let ttl: Int
    let proxied: Bool?
    let priority: Int?
    let comment: String?
    let tags: [String]?
    let data: DNSRecordData?
    
    init(
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

struct BatchDNSRecordDelete: Codable, Sendable {
    let id: String
}

struct BatchDNSRecordsRequest: Codable, Sendable {
    let deletes: [BatchDNSRecordDelete]?
}
