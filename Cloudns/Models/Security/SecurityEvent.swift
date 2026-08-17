import Foundation

struct SecurityGraphQLData: Codable {
    let viewer: SecurityGraphQLViewer
}

struct SecurityGraphQLViewer: Codable {
    let zones: [SecurityGraphQLZone]
}

struct SecurityGraphQLZone: Codable {
    let firewallEventsAdaptive: [SecurityEvent]?
}

struct SecurityEvent: Codable, Identifiable {
    var id: String { datetime + clientIP + ruleId }
    
    let action: String
    let clientIP: String
    let clientCountryName: String
    let clientAsn: String?
    let datetime: String
    let source: String
    let edgeResponseStatus: Int?
    let host: String
    let ruleId: String
    
    enum CodingKeys: String, CodingKey {
        case action
        case clientIP
        case clientCountryName
        case clientAsn
        case datetime
        case source
        case edgeResponseStatus
        case host = "clientRequestHTTPHost"
        case ruleId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.action = (try? container.decode(String.self, forKey: .action)) ?? "block"
        self.clientIP = (try? container.decode(String.self, forKey: .clientIP)) ?? "0.0.0.0"
        self.clientCountryName = (try? container.decode(String.self, forKey: .clientCountryName)) ?? "XX"
        
        if let asnStr = try? container.decode(String.self, forKey: .clientAsn) {
            self.clientAsn = asnStr
        } else if let asnInt = try? container.decode(Int.self, forKey: .clientAsn) {
            self.clientAsn = String(asnInt)
        } else {
            self.clientAsn = nil
        }
        
        self.datetime = (try? container.decode(String.self, forKey: .datetime)) ?? ISO8601DateFormatter().string(from: Date())
        self.source = (try? container.decode(String.self, forKey: .source)) ?? "firewall"
        self.edgeResponseStatus = try? container.decodeIfPresent(Int.self, forKey: .edgeResponseStatus)
        self.host = (try? container.decode(String.self, forKey: .host)) ?? ""
        self.ruleId = (try? container.decode(String.self, forKey: .ruleId)) ?? UUID().uuidString
    }
    
    init(
        action: String = "block",
        clientIP: String = "192.0.2.1",
        clientCountryName: String = "US",
        clientAsn: String? = "13335",
        datetime: String = "2024-01-01T00:00:00Z",
        source: String = "firewallrules",
        edgeResponseStatus: Int? = 403,
        host: String = "example.com",
        ruleId: String = "rule_placeholder"
    ) {
        self.action = action
        self.clientIP = clientIP
        self.clientCountryName = clientCountryName
        self.clientAsn = clientAsn
        self.datetime = datetime
        self.source = source
        self.edgeResponseStatus = edgeResponseStatus
        self.host = host
        self.ruleId = ruleId
    }
    
    static let placeholders: [SecurityEvent] = [
        SecurityEvent(action: "block", clientIP: "198.51.100.4", clientCountryName: "US", ruleId: "1"),
        SecurityEvent(action: "managed_challenge", clientIP: "203.0.113.19", clientCountryName: "DE", ruleId: "2"),
        SecurityEvent(action: "js_challenge", clientIP: "192.0.2.88", clientCountryName: "JP", ruleId: "3")
    ]
}
