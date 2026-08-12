import Foundation

struct SecurityHeader: Codable, Equatable {
    struct StrictTransportSecurity: Codable, Equatable {
        var enabled: Bool
        var max_age: Int
        var include_subdomains: Bool
        var nosniff: Bool
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
        if case .string(let val) = self { return val }
        return nil
    }
    
    var intValue: Int? {
        if case .int(let val) = self { return val }
        return nil
    }
}

struct ZoneSetting: Codable, Identifiable {
    let id: String
    let value: SettingValue
    let editable: Bool?
    let modified_on: String?
}

struct ZoneSettingsResponse: Codable {
    let success: Bool
    let errors: [CloudflareError]?
    let result: [ZoneSetting]?
}

struct ZoneSettingUpdateResponse: Codable {
    let success: Bool
    let errors: [CloudflareError]?
    let result: ZoneSetting?
}
