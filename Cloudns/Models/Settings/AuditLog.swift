import Foundation

// MARK: - Dynamic JSON Value (Swift 6 Sendable)

public enum AnyJSONValue: Codable, Equatable, Sendable, CustomStringConvertible {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnyJSONValue])
    case dictionary([String: AnyJSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else if let d = try? container.decode(Double.self) {
            self = .double(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let arr = try? container.decode([AnyJSONValue].self) {
            self = .array(arr)
        } else if let dict = try? container.decode([String: AnyJSONValue].self) {
            self = .dictionary(dict)
        } else {
            self = .null
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(s): try container.encode(s)
        case let .int(i): try container.encode(i)
        case let .double(d): try container.encode(d)
        case let .bool(b): try container.encode(b)
        case let .array(a): try container.encode(a)
        case let .dictionary(d): try container.encode(d)
        case .null: try container.encodeNil()
        }
    }

    public var description: String {
        switch self {
        case let .string(s): s
        case let .int(i): String(i)
        case let .double(d): String(d)
        case let .bool(b): b ? "true" : "false"
        case let .array(arr): arr.map(\.description).joined(separator: ", ")
        case let .dictionary(dict):
            dict.map { "\($0.key): \($0.value.description)" }.joined(separator: "\n")
        case .null: "null"
        }
    }

    public var prettyJSONString: String {
        switch self {
        case let .string(s): return s
        case .dictionary, .array:
            if let data = try? JSONSerialization.data(withJSONObject: rawObject, options: [.prettyPrinted, .sortedKeys]),
               let str = String(data: data, encoding: .utf8) {
                return str
            }
            return description
        default:
            return description
        }
    }

    public var rawObject: Any {
        switch self {
        case let .string(s): s
        case let .int(i): i
        case let .double(d): d
        case let .bool(b): b
        case let .array(a): a.map(\.rawObject)
        case let .dictionary(d): d.mapValues { $0.rawObject }
        case .null: NSNull()
        }
    }

    public var stringValue: String? {
        switch self {
        case let .string(s): s
        case let .int(i): String(i)
        case let .double(d): String(d)
        case let .bool(b): b ? "true" : "false"
        default: nil
        }
    }

    public subscript(key: String) -> AnyJSONValue? {
        if case let .dictionary(dict) = self {
            return dict[key]
        }
        return nil
    }
}

// MARK: - Audit Logs Models (Cloudflare Audit Logs v2)

public struct AuditZone: Codable, Equatable, Sendable {
    public let id: String?
    public let name: String?

    public init(id: String? = nil, name: String? = nil) {
        self.id = id
        self.name = name
    }
}

public struct AuditActor: Codable, Equatable, Sendable {
    public let id: String?
    public let email: String?
    public let type: String?
    public let ip: String?

    public init(id: String?, email: String?, type: String?, ip: String?) {
        self.id = id
        self.email = email
        self.type = type
        self.ip = ip
    }
}

public struct AuditAction: Codable, Equatable, Sendable {
    public let type: String?
    public let result: Bool?
    public let info: String?

    public init(type: String?, result: Bool?, info: String? = nil) {
        self.type = type
        self.result = result
        self.info = info
    }
}

public struct AuditResource: Codable, Equatable, Sendable {
    public let type: String?
    public let id: String?
    public let scope: String?

    public init(type: String?, id: String?, scope: String? = nil) {
        self.type = type
        self.id = id
        self.scope = scope
    }
}

public struct AuditLog: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let actor: AuditActor?
    public let action: AuditAction?
    public let when: String?
    public let resource: AuditResource?
    public let zone: AuditZone?
    public let interface: String?
    public let newValue: AnyJSONValue?
    public let newValueJson: [String: AnyJSONValue]?
    public let oldValue: AnyJSONValue?
    public let oldValueJson: [String: AnyJSONValue]?
    public let metadata: [String: AnyJSONValue]?

    enum CodingKeys: String, CodingKey {
        case id, actor, action, when, resource, zone, interface
        case newValue, newValueJson
        case oldValue, oldValueJson
        case metadata
    }

    public init(
        id: String,
        actor: AuditActor?,
        action: AuditAction?,
        when: String?,
        resource: AuditResource? = nil,
        zone: AuditZone? = nil,
        interface: String? = nil,
        newValue: AnyJSONValue? = nil,
        newValueJson: [String: AnyJSONValue]? = nil,
        oldValue: AnyJSONValue? = nil,
        oldValueJson: [String: AnyJSONValue]? = nil,
        metadata: [String: AnyJSONValue]? = nil
    ) {
        self.id = id
        self.actor = actor
        self.action = action
        self.when = when
        self.resource = resource
        self.zone = zone
        self.interface = interface
        self.newValue = newValue
        self.newValueJson = newValueJson
        self.oldValue = oldValue
        self.oldValueJson = oldValueJson
        self.metadata = metadata
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        actor = try container.decodeIfPresent(AuditActor.self, forKey: .actor)
        action = try container.decodeIfPresent(AuditAction.self, forKey: .action)
        when = try container.decodeIfPresent(String.self, forKey: .when)
        resource = try container.decodeIfPresent(AuditResource.self, forKey: .resource)
        zone = try container.decodeIfPresent(AuditZone.self, forKey: .zone)
        interface = try container.decodeIfPresent(String.self, forKey: .interface)

        newValue = try? container.decodeIfPresent(AnyJSONValue.self, forKey: .newValue)
        newValueJson = try? container.decodeIfPresent([String: AnyJSONValue].self, forKey: .newValueJson)
        oldValue = try? container.decodeIfPresent(AnyJSONValue.self, forKey: .oldValue)
        oldValueJson = try? container.decodeIfPresent([String: AnyJSONValue].self, forKey: .oldValueJson)
        metadata = try? container.decodeIfPresent([String: AnyJSONValue].self, forKey: .metadata)
    }

    // MARK: - Fully Reactive Localization Keys

    public var displayActionKey: String {
        let raw = (action?.type ?? action?.info ?? "action").lowercased()
        if raw.contains("resume") || raw.contains("unpause") {
            return "Resume"
        } else if raw.contains("pause") {
            return "Pause"
        } else if raw.contains("create") || raw.contains("add") || raw.contains("insert") {
            return "Create"
        } else if raw.contains("delete") || raw.contains("remove") || raw.contains("drop") {
            return "Delete"
        } else if raw.contains("deploy") || raw.contains("publish") {
            return "Deploy"
        } else if raw.contains("order") || raw.contains("subscribe") {
            return "Order"
        } else if raw.contains("update") || raw.contains("edit") || raw.contains("set") || raw.contains("modify") || raw.contains("patch") {
            return "Update"
        } else if raw.contains("purge") || raw.contains("clear") {
            return "Purge Cache"
        } else if raw.contains("rollback") {
            return "Rollback"
        } else if raw.contains("enable") || raw.contains("activate") {
            return "Enable"
        } else if raw.contains("disable") || raw.contains("deactivate") {
            return "Disable"
        } else if raw.contains("login") || raw.contains("auth") {
            return "Login"
        } else if raw.contains("invite") {
            return "Invite"
        } else if raw.contains("revoke") {
            return "Revoke"
        }
        return action?.type?.capitalized ?? "Action"
    }

    public var friendlyResourceTypeKey: String {
        let rawRes = (resource?.type ?? "").lowercased()
        let rawAct = (action?.type ?? action?.info ?? "").lowercased()

        if rawRes.contains("dns") || rawRes.contains("rec") {
            return "DNS Record"
        } else if rawRes.contains("iplist") || rawRes.contains("ip_list") {
            return "IP Access List"
        } else if rawRes.contains("worker") || rawRes.contains("script") {
            return "Worker Script"
        } else if rawRes.contains("page") {
            return "Pages Project"
        } else if rawRes.contains("r2") || rawRes.contains("bucket") {
            return "R2 Bucket"
        } else if rawRes.contains("d1") || rawRes.contains("database") {
            return "D1 Database"
        } else if rawRes.contains("kv") || rawRes.contains("namespace") {
            return "KV Namespace"
        } else if rawRes.contains("cert") || rawRes.contains("ssl") || rawRes.contains("tls") {
            return "SSL/TLS"
        } else if rawRes.contains("firewall") || rawRes.contains("waf") || rawRes.contains("rule") {
            return "WAF Rule"
        } else if rawRes.contains("tunnel") {
            return "Cloudflare Tunnel"
        } else if rawRes.contains("turnstile") {
            return "Turnstile Widget"
        } else if rawRes.contains("access") {
            return "Zero Trust"
        } else if rawRes.contains("zone") {
            return "Zone Config"
        } else if rawRes.contains("account") {
            if rawAct.contains("pause") || rawAct.contains("resume") {
                return "Site Service"
            }
            return "Account Service"
        }
        return resource?.type ?? "Resource Change"
    }

    public var resourceBadge: String {
        let raw = (resource?.type ?? "").lowercased()
        if raw.contains("dns") {
            return "DNS"
        }
        if raw.contains("iplist") {
            return "IP List"
        }
        if raw.contains("worker") {
            return "Worker"
        }
        if raw.contains("page") {
            return "Pages"
        }
        if raw.contains("r2") {
            return "R2"
        }
        if raw.contains("d1") {
            return "D1"
        }
        if raw.contains("kv") {
            return "KV"
        }
        if raw.contains("ssl") || raw.contains("cert") {
            return "SSL"
        }
        if raw.contains("waf") || raw.contains("firewall") {
            return "WAF"
        }
        if raw.contains("tunnel") {
            return "Tunnel"
        }
        if raw.contains("turnstile") {
            return "Turnstile"
        }
        if raw.contains("zone") {
            return "Zone"
        }
        if raw.contains("account") {
            return "Account"
        }
        return resource?.type?.uppercased() ?? "LOG"
    }

    public var actionIcon: String {
        let raw = (action?.type ?? action?.info ?? "").lowercased()
        if raw.contains("resume") || raw.contains("unpause") {
            return "play.circle.fill"
        } else if raw.contains("pause") {
            return "pause.circle.fill"
        } else if raw.contains("create") || raw.contains("add") || raw.contains("insert") {
            return "plus.circle.fill"
        } else if raw.contains("delete") || raw.contains("remove") || raw.contains("drop") {
            return "trash.fill"
        } else if raw.contains("deploy") || raw.contains("publish") {
            return "paperplane.fill"
        } else if raw.contains("order") || raw.contains("subscribe") {
            return "cart.fill"
        } else if raw.contains("update") || raw.contains("edit") || raw.contains("set") || raw.contains("modify") {
            return "pencil.circle.fill"
        } else if raw.contains("purge") || raw.contains("clear") {
            return "arrow.triangle.2.circlepath"
        } else if raw.contains("rollback") {
            return "arrow.uturn.backward.circle.fill"
        } else if raw.contains("enable") {
            return "checkmark.circle.fill"
        } else if raw.contains("disable") {
            return "xmark.circle.fill"
        }
        return "list.bullet.rectangle.fill"
    }
}

private extension String {
    var isHexHash: Bool {
        guard count >= 16 else { return false }
        let hexChars = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        return unicodeScalars.allSatisfy { hexChars.contains($0) }
    }
}
