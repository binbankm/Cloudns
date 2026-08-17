import Foundation
import SwiftUI

// MARK: - Audit Logs Models (Cloudflare Audit Logs v2)

public struct AuditZone: Codable, Equatable {
    public let id: String?
    public let name: String?
    
    public init(id: String? = nil, name: String? = nil) {
        self.id = id
        self.name = name
    }
}

public struct AuditActor: Codable, Equatable {
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

public struct AuditAction: Codable, Equatable {
    public let type: String?
    public let result: Bool?
    public let info: String?
    
    public init(type: String?, result: Bool?, info: String? = nil) {
        self.type = type
        self.result = result
        self.info = info
    }
}

public struct AuditResource: Codable, Equatable {
    public let type: String?
    public let id: String?
    public let scope: String?
    
    public init(type: String?, id: String?, scope: String? = nil) {
        self.type = type
        self.id = id
        self.scope = scope
    }
}

public struct AuditLog: Codable, Identifiable, Equatable {
    public let id: String
    public let actor: AuditActor?
    public let action: AuditAction?
    public let when: String?
    public let resource: AuditResource?
    public let zone: AuditZone?
    public let interface: String?
    public let newValue: String?
    public let oldValue: String?
    public let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, actor, action, when, resource, zone, interface, newValue, oldValue, metadata
    }
    
    public init(
        id: String,
        actor: AuditActor?,
        action: AuditAction?,
        when: String?,
        resource: AuditResource? = nil,
        zone: AuditZone? = nil,
        interface: String? = nil,
        newValue: String? = nil,
        oldValue: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.actor = actor
        self.action = action
        self.when = when
        self.resource = resource
        self.zone = zone
        self.interface = interface
        self.newValue = newValue
        self.oldValue = oldValue
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
        
        if let str = try? container.decodeIfPresent(String.self, forKey: .newValue) {
            self.newValue = str
        } else {
            self.newValue = nil
        }
        
        if let str = try? container.decodeIfPresent(String.self, forKey: .oldValue) {
            self.oldValue = str
        } else {
            self.oldValue = nil
        }
        
        if let metaDict = try? container.decodeIfPresent([String: String].self, forKey: .metadata) {
            self.metadata = metaDict
        } else {
            self.metadata = nil
        }
    }
    
    public var displayAction: String {
        let raw = (action?.type ?? "action").lowercased()
        if raw.contains("create") || raw.contains("add") {
            return "创建"
        } else if raw.contains("delete") || raw.contains("remove") {
            return "删除"
        } else if raw.contains("deploy") {
            return "部署"
        } else if raw.contains("order") {
            return "订购"
        } else if raw.contains("update") || raw.contains("edit") || raw.contains("set") || raw.contains("modify") {
            return "更新"
        } else if raw.contains("purge") {
            return "清除缓存"
        } else if raw.contains("rollback") {
            return "回滚"
        } else if raw.contains("enable") {
            return "启用"
        } else if raw.contains("disable") {
            return "禁用"
        }
        return action?.type?.capitalized ?? "操作"
    }
    
    public var resourceBadge: String {
        let raw = (resource?.type ?? "").lowercased()
        if raw.contains("dns") || raw.contains("rec") {
            return "DNS"
        } else if raw.contains("worker") || raw.contains("script") {
            return "Worker"
        } else if raw.contains("page") {
            return "Pages"
        } else if raw.contains("r2") || raw.contains("bucket") {
            return "R2"
        } else if raw.contains("d1") || raw.contains("database") {
            return "D1"
        } else if raw.contains("kv") || raw.contains("namespace") {
            return "KV"
        } else if raw.contains("cert") || raw.contains("ssl") || raw.contains("tls") {
            return "SSL"
        } else if raw.contains("firewall") || raw.contains("waf") || raw.contains("rule") {
            return "WAF"
        } else if raw.contains("tunnel") {
            return "Tunnel"
        } else if raw.contains("turnstile") {
            return "Turnstile"
        } else if raw.contains("access") {
            return "Access"
        } else if raw.contains("zone") {
            return "Zone"
        }
        return resource?.type?.uppercased() ?? "Resource"
    }
    
    public var displayResourceTitle: String {
        if let name = metadata?["zone_name"], !name.isEmpty {
            return name
        }
        if let name = metadata?["script_name"], !name.isEmpty {
            return name
        }
        if let zoneName = zone?.name, !zoneName.isEmpty {
            return zoneName
        }
        if let resId = resource?.id, !resId.isEmpty {
            return resId
        }
        if let resType = resource?.type, !resType.isEmpty {
            return resType
        }
        return id
    }
    
    public var actionIcon: String {
        let raw = (action?.type ?? "").lowercased()
        if raw.contains("create") || raw.contains("add") {
            return "plus.circle.fill"
        } else if raw.contains("delete") || raw.contains("remove") {
            return "trash.fill"
        } else if raw.contains("deploy") {
            return "paperplane.fill"
        } else if raw.contains("order") {
            return "cart.fill"
        } else if raw.contains("update") || raw.contains("edit") || raw.contains("set") || raw.contains("modify") {
            return "pencil.circle.fill"
        } else if raw.contains("purge") {
            return "arrow.triangle.2.circlepath"
        } else if raw.contains("rollback") {
            return "arrow.uturn.backward.circle.fill"
        }
        return "list.bullet.rectangle.fill"
    }
    
    public var actionColor: Color {
        let raw = (action?.type ?? "").lowercased()
        if raw.contains("create") || raw.contains("add") {
            return .green
        } else if raw.contains("delete") || raw.contains("remove") {
            return .red
        } else if raw.contains("deploy") {
            return .purple
        } else if raw.contains("order") {
            return .orange
        } else if raw.contains("update") || raw.contains("edit") || raw.contains("set") || raw.contains("modify") {
            return .blue
        } else if raw.contains("purge") {
            return .cyan
        } else if raw.contains("rollback") {
            return .brown
        }
        return .secondary
    }
    
    public static let placeholders: [AuditLog] = [
        AuditLog(id: "audit_1", actor: AuditActor(id: "1", email: "admin@example.com", type: "user", ip: "192.0.2.1"), action: AuditAction(type: "zone.dns_record.create", result: true), when: "2024-01-01T12:00:00Z"),
        AuditLog(id: "audit_2", actor: AuditActor(id: "2", email: "dev@example.com", type: "user", ip: "198.51.100.2"), action: AuditAction(type: "worker.script.update", result: true), when: "2024-01-01T11:45:00Z"),
        AuditLog(id: "audit_3", actor: AuditActor(id: "3", email: "system@api", type: "api_key", ip: "203.0.113.1"), action: AuditAction(type: "waf.rule.delete", result: true), when: "2024-01-01T10:30:00Z")
    ]
}
