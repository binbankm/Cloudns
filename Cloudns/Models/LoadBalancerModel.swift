import Foundation

struct LoadBalancer: Codable, Identifiable {
    let id: String
    var name: String?
    var enabled: Bool?
    var ttl: Int?
    var proxied: Bool?
    var defaultPools: [String]?
    var fallbackPool: String?
    var steeringPolicy: String?
    var sessionAffinity: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, enabled, ttl, proxied
        case defaultPools = "default_pools"
        case fallbackPool = "fallback_pool"
        case steeringPolicy = "steering_policy"
        case sessionAffinity = "session_affinity"
    }
}

struct LoadBalancerUpdate: Codable {
    var name: String?
    var enabled: Bool?
    var ttl: Int?
    var proxied: Bool?
    var defaultPools: [String]?
    var fallbackPool: String?
    var steeringPolicy: String?
    var sessionAffinity: String?
    
    enum CodingKeys: String, CodingKey {
        case name, enabled, ttl, proxied
        case defaultPools = "default_pools"
        case fallbackPool = "fallback_pool"
        case steeringPolicy = "steering_policy"
        case sessionAffinity = "session_affinity"
    }
}

struct LBPool: Codable, Identifiable {
    let id: String
    var name: String?
    var enabled: Bool?
    var description: String?
    var minOrigins: Int?
    var monitor: String?
    var origins: [LBOrigin]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, enabled, description, monitor, origins
        case minOrigins = "minimum_origins"
    }
}

struct LBOrigin: Codable, Identifiable {
    let id: String?
    var name: String?
    var address: String?
    var enabled: Bool?
    var weight: Double?
    
    var idResolved: String { id ?? name ?? UUID().uuidString }
}

struct LBMonitor: Codable, Identifiable {
    let id: String
    var type: String?
    var description: String?
    var method: String?
    var path: String?
    var header: [String: [String]]?
    var port: Int?
    var retries: Int?
    var timeout: Int?
    var interval: Int?
    var expectedBody: String?
    var expectedCodes: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, description, method, path, header, port, retries, timeout, interval
        case expectedBody = "expected_body"
        case expectedCodes = "expected_codes"
    }
}

struct LBPoolUpdate: Codable {
    var name: String
    var description: String?
    var enabled: Bool
    var minimumOrigins: Int?
    var monitor: String?
    var origins: [LBOrigin]
    
    enum CodingKeys: String, CodingKey {
        case name, description, enabled, monitor, origins
        case minimumOrigins = "minimum_origins"
    }
}

struct LBMonitorUpdate: Codable {
    var type: String
    var description: String?
    var method: String?
    var path: String?
    var port: Int?
    var retries: Int?
    var timeout: Int?
    var interval: Int?
    var expectedCodes: String?
    
    enum CodingKeys: String, CodingKey {
        case type, description, method, path, port, retries, timeout, interval
        case expectedCodes = "expected_codes"
    }
}
