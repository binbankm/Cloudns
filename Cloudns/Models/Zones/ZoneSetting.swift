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
        case let .string(val): try container.encode(val)
        case let .int(val): try container.encode(val)
        case let .bool(val): try container.encode(val)
        case let .object(val): try container.encode(val)
        case let .securityHeader(val): try container.encode(val)
        case .null: try container.encodeNil()
        case .unknown: break
        }
    }

    var stringValue: String? {
        switch self {
        case let .string(val): val
        case let .bool(val): val ? "on" : "off"
        case let .int(val): String(val)
        default: nil
        }
    }

    var boolValue: Bool {
        switch self {
        case let .bool(val): val
        case let .string(val): val.lowercased() == "on" || val.lowercased() == "true"
        case let .int(val): val == 1
        default: false
        }
    }

    var intValue: Int? {
        switch self {
        case let .int(val): val
        case let .string(val): Int(val)
        default: nil
        }
    }

    var objectValue: [String: String]? {
        if case let .object(val) = self {
            return val
        }
        return nil
    }

    var securityHeaderValue: SecurityHeader? {
        if case let .securityHeader(val) = self {
            return val
        }
        return nil
    }

    var rawAnyValue: Any {
        switch self {
        case let .string(val): val
        case let .int(val): val
        case let .bool(val): val
        case let .object(val): val
        case let .securityHeader(val):
            [
                "strict_transport_security": [
                    "enabled": val.strict_transport_security.enabled,
                    "max_age": val.strict_transport_security.max_age,
                    "include_subdomains": val.strict_transport_security.include_subdomains,
                    "nosniff": val.strict_transport_security.nosniff,
                    "preload": val.strict_transport_security.preload ?? false
                ]
            ]
        case .null, .unknown: ""
        }
    }
}

struct ZoneSetting: Codable, Identifiable, Sendable {
    var id: String {
        rawId ?? UUID().uuidString
    }

    let rawId: String?
    let value: SettingValue
    let editable: Bool?
    let modified_on: String?

    init(id: String? = nil, value: SettingValue, editable: Bool? = nil, modified_on: String? = nil) {
        rawId = id
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

// MARK: - Bot Management Config

public struct BotManagementConfig: Codable, Sendable {
    public let fightMode: Bool?
    public let optimizeWordpress: Bool?
    public let sbfmDefinitelyAutomated: String?
    public let sbfmLikelyAutomated: String?
    public let sbfmVerifiedBots: String?
    public let sbfmStaticResourceProtection: Bool?

    public var fight_mode: Bool? { fightMode }

    enum CodingKeys: String, CodingKey {
        case fightMode = "fight_mode"
        case optimizeWordpress = "optimize_wordpress"
        case sbfmDefinitelyAutomated = "sbfm_definitely_automated"
        case sbfmLikelyAutomated = "sbfm_likely_automated"
        case sbfmVerifiedBots = "sbfm_verified_bots"
        case sbfmStaticResourceProtection = "sbfm_static_resource_protection"
    }

    public init(
        fightMode: Bool? = nil,
        optimizeWordpress: Bool? = nil,
        sbfmDefinitelyAutomated: String? = nil,
        sbfmLikelyAutomated: String? = nil,
        sbfmVerifiedBots: String? = nil,
        sbfmStaticResourceProtection: Bool? = nil
    ) {
        self.fightMode = fightMode
        self.optimizeWordpress = optimizeWordpress
        self.sbfmDefinitelyAutomated = sbfmDefinitelyAutomated
        self.sbfmLikelyAutomated = sbfmLikelyAutomated
        self.sbfmVerifiedBots = sbfmVerifiedBots
        self.sbfmStaticResourceProtection = sbfmStaticResourceProtection
    }

    public init(
        fight_mode: Bool? = nil,
        optimize_wordpress: Bool? = nil,
        sbfm_definitely_automated: String? = nil,
        sbfm_likely_automated: String? = nil,
        sbfm_verified_bots: String? = nil,
        sbfm_static_resource_protection: Bool? = nil
    ) {
        self.fightMode = fight_mode
        self.optimizeWordpress = optimize_wordpress
        self.sbfmDefinitelyAutomated = sbfm_definitely_automated
        self.sbfmLikelyAutomated = sbfm_likely_automated
        self.sbfmVerifiedBots = sbfm_verified_bots
        self.sbfmStaticResourceProtection = sbfm_static_resource_protection
    }
}
