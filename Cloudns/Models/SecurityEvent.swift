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
}
