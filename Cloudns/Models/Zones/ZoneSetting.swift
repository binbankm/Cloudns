import Foundation

struct SecurityHeader: Codable, Equatable, Sendable {
    struct StrictTransportSecurity: Codable, Equatable, Sendable {
        var enabled: Bool
        var max_age: Int
        var include_subdomains: Bool
        var nosniff: Bool
        var preload: Bool?
    }
    var strict_transport_security: StrictTransportSecurity
}

enum SettingValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case object([String: String])
    case securityHeader(SecurityHeader)
    case null
    case unknown
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else if let boolVal = try? container.decode(Bool.self) {
            self = .bool(boolVal)
        } else if let stringVal = try? container.decode(String.self) {
            self = .string(stringVal)
        } else if let securityHeader = try? container.decode(SecurityHeader.self) {
            self = .securityHeader(securityHeader)
        } else if let objVal = try? container.decode([String: String].self) {
            self = .object(objVal)
        } else {
            self = .unknown
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let val): try container.encode(val)
        case .int(let val): try container.encode(val)
        case .bool(let val): try container.encode(val)
        case .object(let val): try container.encode(val)
        case .securityHeader(let val): try container.encode(val)
        case .null: try container.encodeNil()
        case .unknown: break
        }
    }
    
    var stringValue: String? {
        switch self {
        case .string(let val): return val
        case .bool(let val): return val ? "on" : "off"
        case .int(let val): return String(val)
        default: return nil
        }
    }
    
    var boolValue: Bool {
        switch self {
        case .bool(let val): return val
        case .string(let val): return val.lowercased() == "on" || val.lowercased() == "true"
        case .int(let val): return val == 1
        default: return false
        }
    }
    
    var intValue: Int? {
        switch self {
        case .int(let val): return val
        case .string(let val): return Int(val)
        default: return nil
        }
    }
    
    var objectValue: [String: String]? {
        if case .object(let val) = self { return val }
        return nil
    }
    
    var securityHeaderValue: SecurityHeader? {
        if case .securityHeader(let val) = self { return val }
        return nil
    }
    
    var rawAnyValue: Any {
        switch self {
        case .string(let val): return val
        case .int(let val): return val
        case .bool(let val): return val
        case .object(let val): return val
        case .securityHeader(let val):
            return [
                "strict_transport_security": [
                    "enabled": val.strict_transport_security.enabled,
                    "max_age": val.strict_transport_security.max_age,
                    "include_subdomains": val.strict_transport_security.include_subdomains,
                    "nosniff": val.strict_transport_security.nosniff,
                    "preload": val.strict_transport_security.preload ?? false
                ]
            ]
        case .null, .unknown: return ""
        }
    }
}

struct ZoneSetting: Codable, Identifiable, Sendable {
    var id: String { rawId ?? UUID().uuidString }
    let rawId: String?
    let value: SettingValue
    let editable: Bool?
    let modified_on: String?
    
    init(id: String? = nil, value: SettingValue, editable: Bool? = nil, modified_on: String? = nil) {
        self.rawId = id
        self.value = value
        self.editable = editable
        self.modified_on = modified_on
    }
    
    enum CodingKeys: String, CodingKey {
        case rawId = "id"
        case value
        case editable
        case modified_on
    }
}

struct ZoneSettingsResponse: Codable, Sendable {
    let success: Bool
    let errors: [CloudflareError]?
    let result: [ZoneSetting]?
}

struct ZoneSettingUpdateResponse: Codable, Sendable {
    let success: Bool
    let errors: [CloudflareError]?
    let result: ZoneSetting?
}

// MARK: - Bot Management Config

public struct BotManagementConfig: Codable, Sendable {
    public let fight_mode: Bool?
    public let optimize_wordpress: Bool?
    public let sbfm_definitely_automated: String?
    public let sbfm_likely_automated: String?
    public let sbfm_verified_bots: String?
    public let sbfm_static_resource_protection: Bool?
    
    public init(
        fight_mode: Bool? = nil,
        optimize_wordpress: Bool? = nil,
        sbfm_definitely_automated: String? = nil,
        sbfm_likely_automated: String? = nil,
        sbfm_verified_bots: String? = nil,
        sbfm_static_resource_protection: Bool? = nil
    ) {
        self.fight_mode = fight_mode
        self.optimize_wordpress = optimize_wordpress
        self.sbfm_definitely_automated = sbfm_definitely_automated
        self.sbfm_likely_automated = sbfm_likely_automated
        self.sbfm_verified_bots = sbfm_verified_bots
        self.sbfm_static_resource_protection = sbfm_static_resource_protection
    }
}
