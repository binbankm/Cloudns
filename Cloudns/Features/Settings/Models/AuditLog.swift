import Foundation
import SwiftUI

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
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        case .double(let d): try container.encode(d)
        case .bool(let b): try container.encode(b)
        case .array(let a): try container.encode(a)
        case .dictionary(let d): try container.encode(d)
        case .null: try container.encodeNil()
        }
    }

    public var description: String {
        switch self {
        case .string(let s): return s
        case .int(let i): return String(i)
        case .double(let d): return String(d)
        case .bool(let b): return b ? "true" : "false"
        case .array(let arr): return arr.map { $0.description }.joined(separator: ", ")
        case .dictionary(let dict):
            return dict.map { "\($0.key): \($0.value.description)" }.joined(separator: "\n")
        case .null: return "null"
        }
    }

    public var prettyJSONString: String {
        switch self {
        case .string(let s): return s
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
        case .string(let s): return s
        case .int(let i): return i
        case .double(let d): return d
        case .bool(let b): return b
        case .array(let a): return a.map { $0.rawObject }
        case .dictionary(let d): return d.mapValues { $0.rawObject }
        case .null: return NSNull()
        }
    }

    public var stringValue: String? {
        switch self {
        case .string(let s): return s
        case .int(let i): return String(i)
        case .double(let d): return String(d)
        case .bool(let b): return b ? "true" : "false"
        default: return nil
        }
    }

    public subscript(key: String) -> AnyJSONValue? {
        if case .dictionary(let dict) = self {
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
        self.id = try container.decode(String.self, forKey: .id)
        self.actor = try container.decodeIfPresent(AuditActor.self, forKey: .actor)
        self.action = try container.decodeIfPresent(AuditAction.self, forKey: .action)
        self.when = try container.decodeIfPresent(String.self, forKey: .when)
        self.resource = try container.decodeIfPresent(AuditResource.self, forKey: .resource)
        self.zone = try container.decodeIfPresent(AuditZone.self, forKey: .zone)
        self.interface = try container.decodeIfPresent(String.self, forKey: .interface)
        
        self.newValue = try? container.decodeIfPresent(AnyJSONValue.self, forKey: .newValue)
        self.newValueJson = try? container.decodeIfPresent([String: AnyJSONValue].self, forKey: .newValueJson)
        self.oldValue = try? container.decodeIfPresent(AnyJSONValue.self, forKey: .oldValue)
        self.oldValueJson = try? container.decodeIfPresent([String: AnyJSONValue].self, forKey: .oldValueJson)
        self.metadata = try? container.decodeIfPresent([String: AnyJSONValue].self, forKey: .metadata)
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
        if raw.contains("dns") { return "DNS" }
        if raw.contains("iplist") { return "IP List" }
        if raw.contains("worker") { return "Worker" }
        if raw.contains("page") { return "Pages" }
        if raw.contains("r2") { return "R2" }
        if raw.contains("d1") { return "D1" }
        if raw.contains("kv") { return "KV" }
        if raw.contains("ssl") || raw.contains("cert") { return "SSL" }
        if raw.contains("waf") || raw.contains("firewall") { return "WAF" }
        if raw.contains("tunnel") { return "Tunnel" }
        if raw.contains("turnstile") { return "Turnstile" }
        if raw.contains("zone") { return "Zone" }
        if raw.contains("account") { return "Account" }
        return resource?.type?.uppercased() ?? "LOG"
    }
    
    // MARK: - Dynamic SwiftUI Localized Views
    
    @ViewBuilder
    public var primarySummaryView: some View {
        let resType = (resource?.type ?? "").lowercased()
        let actType = (action?.type ?? action?.info ?? "").lowercased()
        
        if actType.contains("resume") || actType.contains("unpause") {
            let zoneName = zone?.name ?? metadata?["zone_name"]?.stringValue ?? metadata?["domain"]?.stringValue
            if let z = zoneName, !z.isEmpty {
                Text("\(z) • Resume Site Proxy")
            } else if let resId = resource?.id, !resId.isEmpty {
                Text("Resume Site Service (ID: \(shortId(resId)))")
            } else {
                Text("Resume Cloudflare Acceleration")
            }
        } else if actType.contains("pause") {
            let zoneName = zone?.name ?? metadata?["zone_name"]?.stringValue ?? metadata?["domain"]?.stringValue
            if let z = zoneName, !z.isEmpty {
                Text("\(z) • Pause Site Proxy")
            } else if let resId = resource?.id, !resId.isEmpty {
                Text("Pause Site Service (ID: \(shortId(resId)))")
            } else {
                Text("Pause Cloudflare Acceleration")
            }
        } else if resType.contains("dns") {
            let recordType = extractString(keys: ["type", "record_type", "rec_type"])
            let recordName = extractString(keys: ["name", "record_name", "rec_name"])
            let content = extractString(keys: ["content", "value", "target", "ip"])
            let zoneName = zone?.name ?? metadata?["zone_name"]?.stringValue
            
            if let type = recordType, let name = recordName ?? zoneName, let c = content {
                Text("\(type) Record • \(name) ➔ \(c)")
            } else if let name = recordName ?? zoneName {
                Text(name)
            } else {
                Text(LocalizedStringKey(friendlyResourceTypeKey))
            }
        } else if resType.contains("iplist") || resType.contains("ip") {
            let ipVal = extractString(keys: ["ip", "value", "item_value", "redirect_url"])
            let listName = extractString(keys: ["list_name", "name", "title"])
            let comment = extractString(keys: ["comment", "description"])
            
            if let ip = ipVal, !ip.isEmpty {
                if let name = listName, !name.isEmpty {
                    Text("\(name) • \(ip)")
                } else {
                    Text("IP List Item: \(ip)")
                }
            } else if let name = listName, !name.isEmpty {
                Text(name)
            } else if let com = comment, !com.isEmpty {
                Text(com)
            } else {
                Text(LocalizedStringKey(friendlyResourceTypeKey))
            }
        } else if resType.contains("zone") || resType.contains("setting") {
            let zoneName = zone?.name ?? metadata?["zone_name"]?.stringValue
            let settingKey = extractString(keys: ["setting_id", "setting_name", "id", "name"])
            let val = extractString(keys: ["value", "mode", "status"])
            let sKey = translateSettingKey(settingKey)
            let vKey = translateSettingValue(val)
            
            if let z = zoneName, !z.isEmpty {
                if let s = sKey, let v = vKey {
                    Text("\(z) • ") + Text(LocalizedStringKey(s)) + Text(": ") + Text(LocalizedStringKey(v))
                } else if let s = sKey {
                    Text("\(z) • ") + Text(LocalizedStringKey(s))
                } else {
                    Text(z)
                }
            } else if let s = sKey {
                if let v = vKey {
                    Text(LocalizedStringKey(s)) + Text(": ") + Text(LocalizedStringKey(v))
                } else {
                    Text(LocalizedStringKey(s))
                }
            } else {
                Text(LocalizedStringKey(friendlyResourceTypeKey))
            }
        } else if resType.contains("worker") || resType.contains("page") {
            let scriptName = extractString(keys: ["script_name", "name", "project_name", "deployment_id"])
            let env = extractString(keys: ["environment", "tag", "branch"])
            if let s = scriptName, !s.isEmpty {
                if let e = env, !e.isEmpty {
                    Text("\(s) (\(e))")
                } else {
                    Text(s)
                }
            } else {
                Text(LocalizedStringKey(friendlyResourceTypeKey))
            }
        } else if resType.contains("waf") || resType.contains("rule") || resType.contains("firewall") {
            let ruleName = extractString(keys: ["description", "rule_name", "name", "action"])
            if let r = ruleName, !r.isEmpty {
                Text(r)
            } else {
                Text(LocalizedStringKey(friendlyResourceTypeKey))
            }
        } else {
            if let name = extractString(keys: ["name", "title", "description"]), !name.isEmpty, !name.isHexHash {
                Text(name)
            } else if let zoneName = zone?.name, !zoneName.isEmpty {
                Text(zoneName)
            } else if let resId = resource?.id, !resId.isEmpty {
                if resId.isHexHash {
                    Text("\(Text(LocalizedStringKey(friendlyResourceTypeKey))) (ID: \(shortId(resId)))")
                } else {
                    Text(resId)
                }
            } else {
                Text("Audit Event \(shortId(id))")
            }
        }
    }
    
    @ViewBuilder
    public var secondaryContextView: some View {
        let zoneName = zone?.name ?? metadata?["zone_name"]?.stringValue
        let listName = extractString(keys: ["list_name"])
        let info = action?.info
        let resId = resource?.id
        
        HStack(spacing: CloudnsSpacing.sm) {
            if let z = zoneName, !z.isEmpty {
                Text("Domain: \(z)")
            }
            if let l = listName, !l.isEmpty {
                Text("List: \(l)")
            }
            if let inf = info, !inf.isEmpty {
                Text(inf)
            }
            if let r = resId, !r.isEmpty, r.isHexHash {
                Text("Resource: \(shortId(r))")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    
    private func extractString(keys: [String]) -> String? {
        // 1. Check newValueJson
        if let newJson = newValueJson {
            for k in keys {
                if let val = newJson[k]?.stringValue, !val.isEmpty { return val }
            }
        }
        // 2. Check oldValueJson
        if let oldJson = oldValueJson {
            for k in keys {
                if let val = oldJson[k]?.stringValue, !val.isEmpty { return val }
            }
        }
        // 3. Check metadata
        if let meta = metadata {
            for k in keys {
                if let val = meta[k]?.stringValue, !val.isEmpty { return val }
            }
        }
        // 4. Check newValue dictionary
        if case .dictionary(let dict) = newValue {
            for k in keys {
                if let val = dict[k]?.stringValue, !val.isEmpty { return val }
            }
        }
        // 5. Check oldValue dictionary
        if case .dictionary(let dict) = oldValue {
            for k in keys {
                if let val = dict[k]?.stringValue, !val.isEmpty { return val }
            }
        }
        return nil
    }
    
    private func translateSettingKey(_ key: String?) -> String? {
        guard let key = key?.lowercased() else { return nil }
        switch key {
        case "dev_mode", "development_mode": return "Development Mode"
        case "always_online": return "Always Online"
        case "ssl", "ssl_mode": return "SSL Encryption Mode"
        case "security_level": return "Security Level"
        case "challenge_ttl": return "Challenge TTL"
        case "browser_cache_ttl": return "Browser Cache TTL"
        case "cache_level": return "Cache Level"
        case "minify": return "Auto Minify"
        case "brotli": return "Brotli Compression"
        case "http2": return "HTTP/2"
        case "http3": return "HTTP/3 (QUIC)"
        case "0rtt": return "0-RTT Connection"
        case "tls_1_3": return "TLS 1.3"
        case "min_tls_version": return "Minimum TLS Version"
        case "websockets": return "WebSockets"
        case "automatic_https_rewrites": return "Automatic HTTPS Rewrites"
        case "ip_geolocation": return "IP Geolocation"
        case "email_obfuscation": return "Email Obfuscation"
        case "server_side_exclude": return "Server-side Excludes"
        case "hotlink_protection": return "Hotlink Protection"
        case "rocket_loader": return "Rocket Loader"
        case "polish": return "Polish Image Optimization"
        case "mirage": return "Mirage Mobile Optimization"
        case "ipv6": return "IPv6 Compatibility"
        case "pseudo_ipv4": return "Pseudo IPv4"
        case "waf": return "WAF Firewall"
        case "early_hints": return "Early Hints"
        case "h2_prioritization": return "HTTP/2 Prioritization"
        case "origin_error_page_pass_thru": return "Origin Error Page Pass-thru"
        case "proxy_read_timeout": return "Proxy Read Timeout"
        default: return key
        }
    }
    
    private func translateSettingValue(_ val: String?) -> String? {
        guard let val = val?.lowercased() else { return nil }
        switch val {
        case "on", "true", "1": return "On"
        case "off", "false", "0": return "Off"
        case "strict": return "Full (Strict)"
        case "full": return "Full"
        case "flexible": return "Flexible"
        case "essentially_off": return "Essentially Off"
        case "low": return "Low"
        case "medium": return "Medium"
        case "high": return "High"
        case "under_attack": return "Under Attack"
        default: return val
        }
    }
    
    private func shortId(_ id: String) -> String {
        if id.count > 12 {
            return String(id.prefix(8)) + "..."
        }
        return id
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
    
    public var actionColor: Color {
        let raw = (action?.type ?? action?.info ?? "").lowercased()
        if raw.contains("resume") || raw.contains("unpause") {
            return .green
        } else if raw.contains("pause") {
            return .orange
        } else if raw.contains("create") || raw.contains("add") || raw.contains("insert") {
            return .green
        } else if raw.contains("delete") || raw.contains("remove") || raw.contains("drop") {
            return .red
        } else if raw.contains("deploy") || raw.contains("publish") {
            return .purple
        } else if raw.contains("order") {
            return .orange
        } else if raw.contains("update") || raw.contains("edit") || raw.contains("set") || raw.contains("modify") {
            return .blue
        } else if raw.contains("purge") || raw.contains("clear") {
            return .cyan
        } else if raw.contains("rollback") {
            return .brown
        }
        return .secondary
    }
    
    public static let placeholders: [AuditLog] = [
        AuditLog(
            id: "audit_1",
            actor: AuditActor(id: "1", email: "admin@example.com", type: "user", ip: "192.0.2.1"),
            action: AuditAction(type: "create", result: true, info: "CreateDNSRecord"),
            when: "2024-01-01T12:00:00Z",
            resource: AuditResource(type: "zone.dns_record", id: "rec_123"),
            zone: AuditZone(id: "z1", name: "08060331.xyz"),
            newValueJson: ["type": .string("A"), "name": .string("api.08060331.xyz"), "content": .string("192.0.2.1")]
        ),
        AuditLog(
            id: "audit_2",
            actor: AuditActor(id: "2", email: "dev@example.com", type: "user", ip: "198.51.100.2"),
            action: AuditAction(type: "delete", result: true, info: "DeleteItem"),
            when: "2024-01-01T11:45:00Z",
            resource: AuditResource(type: "account.iplists", id: "list_456"),
            metadata: ["list_name": .string("Threat Blocklist"), "ip": .string("38.134.40.39")]
        ),
        AuditLog(
            id: "audit_3",
            actor: AuditActor(id: "3", email: "system@api", type: "api_key", ip: "203.0.113.1"),
            action: AuditAction(type: "update", result: true, info: "UpdateZoneSetting"),
            when: "2024-01-01T10:30:00Z",
            resource: AuditResource(type: "zone.settings", id: "dev_mode"),
            zone: AuditZone(id: "z1", name: "08060331.xyz"),
            newValueJson: ["setting_id": .string("dev_mode"), "value": .string("on")]
        )
    ]
}

private extension String {
    var isHexHash: Bool {
        guard count >= 16 else { return false }
        let hexChars = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        return unicodeScalars.allSatisfy { hexChars.contains($0) }
    }
}
