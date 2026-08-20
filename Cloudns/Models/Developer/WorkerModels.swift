import Foundation

// MARK: - Workers Models

public struct WorkerScript: Codable, Identifiable, Equatable, Sendable {
    public var id: String { id_field ?? id_name ?? "worker" }
    public let id_field: String?
    public let id_name: String?
    public let etag: String?
    public let modifiedOn: String?
    public let createdOn: String?
    public let usageModel: String?
    public let compatibilityDate: String?
    public let routes: [String]?
    public let cronTriggers: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id_field = "id"
        case id_name = "id_name"
        case etag
        case modifiedOn = "modified_on"
        case createdOn = "created_on"
        case usageModel = "usage_model"
        case compatibilityDate = "compatibility_date"
        case routes
        case cronTriggers = "cron_triggers"
    }
    
    public init(id: String, modifiedOn: String? = "2024-01-01T00:00:00Z", usageModel: String? = "bundled", routes: [String]? = ["example.com/*"]) {
        self.id_field = id
        self.id_name = id
        self.etag = "placeholder"
        self.modifiedOn = modifiedOn
        self.createdOn = "2024-01-01T00:00:00Z"
        self.usageModel = usageModel
        self.compatibilityDate = "2024-01-01"
        self.routes = routes
        self.cronTriggers = []
    }
    
    public static let placeholders: [WorkerScript] = (0..<6).map { idx in
        WorkerScript(id: "worker-service-\(idx + 1)")
    }
}

public struct WorkerModuleItem: Identifiable, Hashable, Codable, Sendable {
    public var id: String { name }
    public let name: String
    public let code: String
    public let isMain: Bool
    public let contentType: String?
    
    public init(name: String, code: String, isMain: Bool = false, contentType: String? = nil) {
        self.name = name
        self.code = code
        self.isMain = isMain
        self.contentType = contentType
    }
}

public struct WorkerScriptContentResult: Equatable, Sendable {
    public let rawCode: String
    public let modules: [WorkerModuleItem]
    public let mainModuleName: String?
    public let isMultiModule: Bool
    
    public init(rawCode: String, modules: [WorkerModuleItem] = [], mainModuleName: String? = nil) {
        self.rawCode = rawCode
        self.modules = modules
        self.mainModuleName = mainModuleName
        self.isMultiModule = modules.count > 1
    }
}

public struct WorkerBinding: Codable, Identifiable, Equatable, Sendable {
    public var id: String { name }
    public let name: String
    public let type: String
    public let namespaceId: String?
    public let bucketName: String?
    public let databaseId: String?
    public let text: String?
    public let queueName: String?
    public let service: String?
    public let environment: String?
    
    public init(
        name: String,
        type: String = "plain_text",
        namespaceId: String? = nil,
        bucketName: String? = nil,
        databaseId: String? = nil,
        text: String? = nil,
        queueName: String? = nil,
        service: String? = nil,
        environment: String? = nil
    ) {
        self.name = name
        self.type = type
        self.namespaceId = namespaceId
        self.bucketName = bucketName
        self.databaseId = databaseId
        self.text = text
        self.queueName = queueName
        self.service = service
        self.environment = environment
    }
    
    enum CodingKeys: String, CodingKey {
        case name, type, service, environment
        case namespaceId = "namespace_id"
        case bucketName = "bucket_name"
        case databaseId = "database_id"
        case queueName = "queue_name"
        case text
    }
    
    public static let placeholders: [WorkerBinding] = (0..<6).map { idx in
        WorkerBinding(name: "ENV_VARIABLE_\(idx + 1)", type: "plain_text", text: "placeholder_value_\(idx + 1)")
    }
}

public struct WorkerSecret: Codable, Identifiable, Equatable, Sendable {
    public var id: String { name }
    public let name: String
    public let type: String
    public let modifiedOn: String?
    
    public init(name: String, type: String = "secret_text", modifiedOn: String? = "2024-01-01T00:00:00Z") {
        self.name = name
        self.type = type
        self.modifiedOn = modifiedOn
    }
    
    enum CodingKeys: String, CodingKey {
        case name, type
        case modifiedOn = "modified_on"
    }
    
    public static let placeholders: [WorkerSecret] = (0..<6).map { idx in
        WorkerSecret(name: "SECRET_KEY_\(idx + 1)", type: "secret_text", modifiedOn: "2024-01-01T00:00:00Z")
    }
}

public struct WorkerCustomRoute: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let pattern: String
    public let script: String?
}

public struct WorkerCustomDomain: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let hostname: String
    public let zoneName: String?
    public let zoneId: String?
    public let service: String?
    
    enum CodingKeys: String, CodingKey {
        case id, hostname, service
        case zoneName = "zone_name"
        case zoneId = "zone_id"
    }
    
    public init(id: String, hostname: String, zoneName: String? = nil, zoneId: String? = nil, service: String? = nil) {
        self.id = id
        self.hostname = hostname
        self.zoneName = zoneName
        self.zoneId = zoneId
        self.service = service
    }
    
    public static let placeholders: [WorkerCustomDomain] = [
        WorkerCustomDomain(id: "dom_1", hostname: "api.example.com", zoneName: "example.com"),
        WorkerCustomDomain(id: "dom_2", hostname: "auth.example.com", zoneName: "example.com")
    ]
}

public struct WorkerSubdomain: Codable, Equatable, Sendable {
    public let id: String?
    public let enabled: Bool
}

public struct WorkerSchedule: Codable, Identifiable, Equatable, Sendable {
    public var id: String { cron }
    public let cron: String
    public let createdOn: String?
    public let modifiedOn: String?
    
    enum CodingKeys: String, CodingKey {
        case cron
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
    }
    
    public init(cron: String, createdOn: String? = nil, modifiedOn: String? = nil) {
        self.cron = cron
        self.createdOn = createdOn
        self.modifiedOn = modifiedOn
    }
    
    public static let placeholders: [WorkerSchedule] = [
        WorkerSchedule(cron: "*/5 * * * *", createdOn: "2024-01-01T00:00:00Z"),
        WorkerSchedule(cron: "0 0 * * *", createdOn: "2024-01-01T00:00:00Z")
    ]
}

public struct WorkerSchedulesResult: Codable, Sendable {
    public let schedules: [WorkerSchedule]?
}

public struct WorkerScheduleInput: Codable, Sendable {
    public let cron: String
}

public struct WorkerTailSession: Codable, Sendable {
    public let id: String
    public let url: String
    public let expiresAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, url
        case expiresAt = "expires_at"
    }
}

public struct TailTraceItem: Codable, Identifiable, Sendable {
    public var id = UUID()
    public let outcome: String?
    public let scriptName: String?
    public let eventTimestamp: Int?
    public let event: TailEventInfo?
    public let logs: [TailLog]?
    public let exceptions: [TailException]?
    
    enum CodingKeys: String, CodingKey {
        case outcome, scriptName, eventTimestamp, event, logs, exceptions
    }
}

public struct TailEventInfo: Codable, Sendable {
    public let request: TailRequestInfo?
    public let cron: String?
}

public struct TailRequestInfo: Codable, Sendable {
    public let url: String?
    public let method: String?
}

public struct TailLog: Codable, Identifiable, Sendable {
    public var id = UUID()
    public let level: String?
    public let timestamp: Int?
    public let message: [JSONValue]?
    
    enum CodingKeys: String, CodingKey {
        case level, timestamp, message
    }
}

public struct TailException: Codable, Identifiable, Sendable {
    public var id = UUID()
    public let name: String?
    public let message: String?
    public let timestamp: Int?
    
    enum CodingKeys: String, CodingKey {
        case name, message, timestamp
    }
}

public indirect enum JSONValue: Codable, Sendable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            self = .string("")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value):   try container.encode(value)
        case .null:              try container.encodeNil()
        case .array(let value):  try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }

    public var displayText: String {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return value.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(value))
                : String(value)
        case .bool(let value):
            return value ? "true" : "false"
        case .null:
            return "null"
        case .array(let values):
            return "[" + values.map(\.displayText).joined(separator: ", ") + "]"
        case .object(let dict):
            let pairs = dict.sorted { $0.key < $1.key }
                .map { "\($0.key): \($0.value.displayText)" }
            return "{" + pairs.joined(separator: ", ") + "}"
        }
    }
}

public struct WorkerZoneRoute: Codable, Identifiable, Equatable {
    public let id: String
    public let pattern: String
    public let script: String?
    public let requestLimitFailOpen: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, pattern, script
        case requestLimitFailOpen = "request_limit_fail_open"
    }
    
    public init(id: String, pattern: String, script: String?, requestLimitFailOpen: Bool? = nil) {
        self.id = id
        self.pattern = pattern
        self.script = script
        self.requestLimitFailOpen = requestLimitFailOpen
    }
}

// MARK: - Worker Deployment Models

public struct WorkerDeployment: Codable, Identifiable, Equatable, Sendable {
    public var id: String { id_field ?? uuid ?? "deployment-\(number ?? 1)" }
    public let id_field: String?
    public let uuid: String?
    public let number: Int?
    public let createdOn: String?
    public let author: String?
    public let authorEmail: String?
    public let source: String?
    public let strategy: String?
    public let annotations: WorkerDeploymentAnnotations?
    public let compatibilityDate: String?
    public let usageModel: String?
    
    enum CodingKeys: String, CodingKey {
        case id_field = "id"
        case uuid
        case number
        case createdOn = "created_on"
        case author
        case authorEmail = "author_email"
        case source
        case strategy
        case annotations
        case compatibilityDate = "compatibility_date"
        case usageModel = "usage_model"
    }
    
    public init(
        id: String,
        number: Int? = 1,
        createdOn: String? = "2024-01-01T00:00:00Z",
        authorEmail: String? = "developer@example.com",
        source: String? = "dash",
        annotations: WorkerDeploymentAnnotations? = nil
    ) {
        self.id_field = id
        self.uuid = id
        self.number = number
        self.createdOn = createdOn
        self.author = authorEmail
        self.authorEmail = authorEmail
        self.source = source
        self.strategy = "percentage"
        self.annotations = annotations
        self.compatibilityDate = "2024-01-01"
        self.usageModel = "bundled"
    }
    
    public var displaySource: String {
        guard let s = source, !s.isEmpty else { return "Dashboard" }
        switch s.lowercased() {
        case "wrangler": return "Wrangler CLI"
        case "dash", "dashboard": return "Cloudflare Dashboard"
        case "api": return "Cloudflare API"
        case "github", "git": return "Git Integration"
        case "rollback": return "Rollback"
        default: return s.capitalized
        }
    }
    
    public static let placeholders: [WorkerDeployment] = (1...4).reversed().map { num in
        WorkerDeployment(
            id: "d-\(num)-uuid-deployment",
            number: num,
            createdOn: "2024-01-0\(num)T12:00:00Z",
            authorEmail: "admin@cloudflare.com",
            source: num == 4 ? "wrangler" : "dash",
            annotations: WorkerDeploymentAnnotations(message: "Release v1.\(num).0 - Production updates", triggeredBy: "upload")
        )
    }
}

public struct WorkerDeploymentAnnotations: Codable, Equatable, Sendable {
    public let message: String?
    public let triggeredBy: String?
    
    enum CodingKeys: String, CodingKey {
        case message = "workers/message"
        case triggeredBy = "workers/triggered_by"
    }
    
    public init(message: String? = nil, triggeredBy: String? = nil) {
        self.message = message
        self.triggeredBy = triggeredBy
    }
}

public struct WorkerDeploymentsResult: Codable, Sendable {
    public let deployments: [WorkerDeployment]?
}
