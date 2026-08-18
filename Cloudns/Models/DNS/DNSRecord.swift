import Foundation

struct DNSRecord: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let type: String
    let name: String
    let content: String?
    let proxiable: Bool?
    let proxied: Bool?
    let ttl: Int
    let locked: Bool?
    let zoneId: String?
    let zoneName: String?
    let modifiedOn: String?
    let createdOn: String?
    let priority: Int?
    let comment: String?
    let data: DNSRecordData?
    
    enum CodingKeys: String, CodingKey {
        case id, type, name, content, proxiable, proxied, ttl, locked, priority, comment, data
        case zoneId = "zone_id"
        case zoneName = "zone_name"
        case modifiedOn = "modified_on"
        case createdOn = "created_on"
    }
    
    static var dummyData: [DNSRecord] {
        return (0..<5).map { i in
            DNSRecord(
                id: "dummy-\(i)",
                type: "A",
                name: "example.com",
                content: "192.168.1.1",
                proxiable: true,
                proxied: true,
                ttl: 1,
                locked: false,
                zoneId: "dummy-zone",
                zoneName: "example.com",
                modifiedOn: nil,
                createdOn: nil,
                priority: nil,
                comment: "Dummy comment",
                data: nil
            )
        }
    }
    
    static var placeholders: [DNSRecord] {
        dummyData
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
}

struct DNSRecordPayload: Codable, Sendable {
    let type: String
    let name: String
    let content: String?
    let ttl: Int
    let proxied: Bool?
    let priority: Int?
    let comment: String?
    let data: DNSRecordData?
}

struct BatchDNSRecordDelete: Codable, Sendable {
    let id: String
}

struct BatchDNSRecordsRequest: Codable, Sendable {
    let deletes: [BatchDNSRecordDelete]?
}
