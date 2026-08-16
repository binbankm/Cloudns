import Foundation

// MARK: - Workers Models

public struct WorkerScript: Codable, Identifiable, Equatable {
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

public struct WorkerModuleItem: Identifiable, Hashable, Codable {
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

public struct WorkerScriptContentResult: Equatable {
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

public struct WorkerBinding: Codable, Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let type: String
    public let namespaceId: String?
    public let bucketName: String?
    public let databaseId: String?
    public let text: String?
    
    public init(name: String, type: String = "plain_text", namespaceId: String? = nil, bucketName: String? = nil, databaseId: String? = nil, text: String? = nil) {
        self.name = name
        self.type = type
        self.namespaceId = namespaceId
        self.bucketName = bucketName
        self.databaseId = databaseId
        self.text = text
    }
    
    enum CodingKeys: String, CodingKey {
        case name, type
        case namespaceId = "namespace_id"
        case bucketName = "bucket_name"
        case databaseId = "database_id"
        case text
    }
    
    public static let placeholders: [WorkerBinding] = (0..<6).map { idx in
        WorkerBinding(name: "ENV_VARIABLE_\(idx + 1)", type: "plain_text", text: "placeholder_value_\(idx + 1)")
    }
}

public struct WorkerSecret: Codable, Identifiable, Equatable {
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

public struct WorkerCustomRoute: Codable, Identifiable, Equatable {
    public let id: String
    public let pattern: String
    public let script: String?
}

public struct WorkerCustomDomain: Codable, Identifiable, Equatable {
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

public struct WorkerSubdomain: Codable, Equatable {
    public let id: String?
    public let enabled: Bool
}

public struct WorkerSchedule: Codable, Identifiable, Equatable {
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

public struct WorkerSchedulesResult: Codable {
    public let schedules: [WorkerSchedule]?
}

public struct WorkerScheduleInput: Codable {
    public let cron: String
}

public struct WorkerTailSession: Codable {
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

public indirect enum JSONValue: Codable, Sendable {
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

// MARK: - Pages Models

public struct PagesProject: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let subdomain: String?
    public let domains: [String]?
    public let productionBranch: String?
    public let createdOn: String?
    public let buildConfig: PagesBuildConfig?
    public let source: PagesProjectSource?
    public let deploymentConfigs: PagesDeploymentConfigs?
    
    enum CodingKeys: String, CodingKey {
        case id, name, subdomain, domains
        case productionBranch = "production_branch"
        case createdOn = "created_on"
        case buildConfig = "build_config"
        case source
        case deploymentConfigs = "deployment_configs"
    }
    
    public init(id: String, name: String, subdomain: String? = "pages.dev", domains: [String]? = nil, productionBranch: String? = "main") {
        self.id = id
        self.name = name
        self.subdomain = subdomain
        self.domains = domains
        self.productionBranch = productionBranch
        self.createdOn = "2024-01-01T00:00:00Z"
        self.buildConfig = nil
        self.source = nil
        self.deploymentConfigs = nil
    }
    
    public static let placeholders: [PagesProject] = (0..<6).map { idx in
        PagesProject(id: "project-\(idx + 1)", name: "pages-web-app-\(idx + 1)", subdomain: "pages-web-app-\(idx + 1).pages.dev")
    }
}

public struct PagesProjectSource: Codable, Equatable {
    public let type: String?
    public let config: PagesProjectSourceConfig?
}

public struct PagesProjectSourceConfig: Codable, Equatable {
    public let repoName: String?
    public let owner: String?
    public let productionBranch: String?
    
    enum CodingKeys: String, CodingKey {
        case repoName = "repo_name"
        case owner
        case productionBranch = "production_branch"
    }
}

public struct PagesDeploymentConfigs: Codable, Equatable {
    public let production: PagesEnvConfig?
    public let preview: PagesEnvConfig?
}

public struct PagesEnvConfig: Codable, Equatable {
    public let envVars: [String: PagesEnvVarValue]?
    public let compatibilityDate: String?
    public let compatibilityFlags: [String]?
    public let d1Databases: [String: PagesD1Binding]?
    public let kvNamespaces: [String: PagesKVBinding]?
    public let r2Buckets: [String: PagesR2Binding]?
    public let aiBindings: [String: PagesAIBinding]?
    public let queueProducers: [String: PagesQueueBinding]?
    
    enum CodingKeys: String, CodingKey {
        case envVars = "env_vars"
        case compatibilityDate = "compatibility_date"
        case compatibilityFlags = "compatibility_flags"
        case d1Databases = "d1_databases"
        case kvNamespaces = "kv_namespaces"
        case r2Buckets = "r2_buckets"
        case aiBindings = "ai_bindings"
        case queueProducers = "queue_producers"
    }
}

public struct PagesEnvVarValue: Codable, Equatable {
    public let value: String?
    public let type: String?
    
    public var isSecret: Bool { type == "secret_text" }
}

public struct PagesD1Binding: Codable, Equatable {
    public let id: String?
}

public struct PagesKVBinding: Codable, Equatable {
    public let namespaceId: String?
    enum CodingKeys: String, CodingKey {
        case namespaceId = "namespace_id"
    }
}

public struct PagesR2Binding: Codable, Equatable {
    public let name: String?
}

public struct PagesAIBinding: Codable, Equatable {
    public let projectId: String?
    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
    }
}

public struct PagesQueueBinding: Codable, Equatable {
    public let name: String?
}

public struct PagesBuildConfig: Codable, Equatable {
    public let buildCommand: String?
    public let destinationDir: String?
    public let rootDir: String?
    public let webAnalyticsTag: String?
    public let webAnalyticsToken: String?
    
    enum CodingKeys: String, CodingKey {
        case buildCommand = "build_command"
        case destinationDir = "destination_dir"
        case rootDir = "root_dir"
        case webAnalyticsTag = "web_analytics_tag"
        case webAnalyticsToken = "web_analytics_token"
    }
}

public struct PagesDomain: Codable, Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let status: String?
    public let sslStatus: String?
    public let verificationStatus: String?
    public let createdOn: String?
    
    enum CodingKeys: String, CodingKey {
        case name, status
        case sslStatus = "ssl_status"
        case verificationStatus = "verification_status"
        case createdOn = "created_on"
    }
    
    public init(
        name: String,
        status: String? = "active",
        sslStatus: String? = "active",
        verificationStatus: String? = "active",
        createdOn: String? = "2024-01-01T00:00:00Z"
    ) {
        self.name = name
        self.status = status
        self.sslStatus = sslStatus
        self.verificationStatus = verificationStatus
        self.createdOn = createdOn
    }
    
    public static let placeholders: [PagesDomain] = [
        PagesDomain(name: "docs.example.com"),
        PagesDomain(name: "app.example.com")
    ]
}

public struct PagesDeployment: Codable, Identifiable, Equatable {
    public let id: String
    public let url: String?
    public let environment: String?
    public let createdOn: String?
    public let modifiedOn: String?
    public let latestStage: PagesStage?
    public let deploymentTrigger: PagesTrigger?
    
    enum CodingKeys: String, CodingKey {
        case id, url, environment
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
        case latestStage = "latest_stage"
        case deploymentTrigger = "deployment_trigger"
    }
    
    public init(
        id: String,
        url: String? = nil,
        environment: String? = "production",
        createdOn: String? = "2024-01-01T00:00:00Z",
        modifiedOn: String? = nil,
        latestStage: PagesStage? = PagesStage(name: "deploy", status: "success", startedOn: nil, endedOn: nil),
        deploymentTrigger: PagesTrigger? = nil
    ) {
        self.id = id
        self.url = url
        self.environment = environment
        self.createdOn = createdOn
        self.modifiedOn = modifiedOn
        self.latestStage = latestStage
        self.deploymentTrigger = deploymentTrigger
    }
    
    public static let placeholders: [PagesDeployment] = [
        PagesDeployment(id: "dep_1", environment: "production"),
        PagesDeployment(id: "dep_2", environment: "preview")
    ]
}

public struct PagesDeploymentLog: Codable, Identifiable, Equatable {
    public var id: String { "\(ts)-\(line.hashValue)" }
    public let ts: String
    public let line: String
}

public struct PagesDeploymentLogsResult: Codable {
    public let total: Int?
    public let data: [PagesDeploymentLog]?
}

public struct PagesStage: Codable, Equatable {
    public let name: String?
    public let status: String?
    public let startedOn: String?
    public let endedOn: String?
    
    public init(name: String? = nil, status: String? = nil, startedOn: String? = nil, endedOn: String? = nil) {
        self.name = name
        self.status = status
        self.startedOn = startedOn
        self.endedOn = endedOn
    }
    
    enum CodingKeys: String, CodingKey {
        case name, status
        case startedOn = "started_on"
        case endedOn = "ended_on"
    }
}

public struct PagesTrigger: Codable, Equatable {
    public let type: String?
    public let metadata: PagesTriggerMetadata?
}

public struct PagesTriggerMetadata: Codable, Equatable {
    public let branch: String?
    public let commitHash: String?
    public let commitMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case branch
        case commitHash = "commit_hash"
        case commitMessage = "commit_message"
    }
}

// MARK: - R2 Storage Models

public struct R2Bucket: Codable, Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let creationDate: String?
    public let location: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case creationDate = "creation_date"
        case location
    }
    
    public init(name: String, creationDate: String? = "2024-01-01T00:00:00Z", location: String? = "WNAM") {
        self.name = name
        self.creationDate = creationDate
        self.location = location
    }
    
    public static let placeholders: [R2Bucket] = (0..<5).map { idx in
        R2Bucket(name: "assets-storage-bucket-\(idx + 1)")
    }
}

public struct R2Object: Codable, Identifiable, Equatable {
    public var id: String { key }
    public let key: String
    public let size: Int
    public let etag: String?
    public let version: String?
    public let uploaded: String?
    public let storageClass: String?
    
    enum CodingKeys: String, CodingKey {
        case key, size, etag, version, uploaded
        case storageClass = "storage_class"
    }
    
    public var formattedSize: String {
        let b = Double(size)
        if b < 1024 { return "\(size) B" }
        let kb = b / 1024.0
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024.0
        if mb < 1024 { return String(format: "%.1f MB", mb) }
        let gb = mb / 1024.0
        return String(format: "%.2f GB", gb)
    }
    
    public init(
        key: String,
        size: Int = 1048576,
        etag: String? = "d41d8cd98f00b204e9800998ecf8427e",
        version: String? = "v1",
        uploaded: String? = "2024-01-01T00:00:00Z",
        storageClass: String? = "Standard"
    ) {
        self.key = key
        self.size = size
        self.etag = etag
        self.version = version
        self.uploaded = uploaded
        self.storageClass = storageClass
    }
    
    public static let placeholders: [R2Object] = [
        R2Object(key: "assets/logo.png", size: 45000),
        R2Object(key: "backups/db-2024.sql.gz", size: 104857600),
        R2Object(key: "configs/app.json", size: 2400)
    ]
}

// MARK: - KV Storage Models

public struct KVNamespace: Codable, Identifiable, Equatable {
    public let id: String
    public let title: String
    public let supportsUrlEncoding: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, title
        case supportsUrlEncoding = "supports_url_encoding"
    }
    
    public init(id: String, title: String, supportsUrlEncoding: Bool? = true) {
        self.id = id
        self.title = title
        self.supportsUrlEncoding = supportsUrlEncoding
    }
    
    public static let placeholders: [KVNamespace] = (0..<4).map { idx in
        KVNamespace(id: "kv-ns-uuid-\(idx + 1)-abcd", title: "SESSION_CACHE_\(idx + 1)")
    }
}

public struct KVKey: Codable, Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let expiration: Int?
    public let metadata: String?
    
    public init(name: String, expiration: Int? = nil, metadata: String? = nil) {
        self.name = name
        self.expiration = expiration
        self.metadata = metadata
    }
    
    public static let placeholders: [KVKey] = (0..<6).map { idx in
        KVKey(name: "user:session:token_\(idx + 1)")
    }
}

// MARK: - D1 Database Models

public struct D1Database: Codable, Identifiable, Equatable {
    public var id: String { uuid }
    public let uuid: String
    public let name: String
    public let version: String?
    public let numTables: Int?
    public let fileSize: Int?
    public let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case uuid, name, version
        case numTables = "num_tables"
        case fileSize = "file_size"
        case createdAt = "created_at"
    }
    
    public init(uuid: String, name: String, numTables: Int? = 4, fileSize: Int? = 1048576, createdAt: String? = "2024-01-01T00:00:00Z") {
        self.uuid = uuid
        self.name = name
        self.version = "beta"
        self.numTables = numTables
        self.fileSize = fileSize
        self.createdAt = createdAt
    }
    
    public static let placeholders: [D1Database] = (0..<4).map { idx in
        D1Database(uuid: "d1-uuid-\(idx + 1)-db", name: "production-users-db-\(idx + 1)")
    }
    
    public var formattedSize: String {
        guard let size = fileSize else { return "0 B" }
        let b = Double(size)
        if b < 1024 { return "\(size) B" }
        let kb = b / 1024.0
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024.0
        return String(format: "%.2f MB", mb)
    }
}

public struct D1QueryResult: Equatable {
    public let success: Bool
    public let query: String
    public let durationMs: Double
    public let rowsRead: Int
    public let rowsWritten: Int
    public let columns: [String]
    public let rows: [[String: String]]
    public let rawJson: String?
}

// MARK: - R2 Advanced Settings Models

public struct R2ManagedDomain: Codable, Equatable {
    public let domain: String?
    public let enabled: Bool?
}

public struct R2CustomDomain: Codable, Identifiable, Equatable {
    public var id: String { domain }
    public let domain: String
    public let status: String?
    public let zoneId: String?
    public let enabled: Bool?
    
    enum CodingKeys: String, CodingKey {
        case domain, status, enabled
        case zoneId = "zone_id"
    }
    
    public init(domain: String, status: String? = "active", zoneId: String? = "zone_123", enabled: Bool? = true) {
        self.domain = domain
        self.status = status
        self.zoneId = zoneId
        self.enabled = enabled
    }
    
    public static let placeholders: [R2CustomDomain] = [
        R2CustomDomain(domain: "cdn.example.com"),
        R2CustomDomain(domain: "static.example.com")
    ]
}

public struct R2CORSRule: Codable, Identifiable, Equatable {
    public var id: String { "\(allowedOrigins.joined(separator: ","))-\(allowedMethods.joined(separator: ","))" }
    public var allowedOrigins: [String]
    public var allowedMethods: [String]
    public var allowedHeaders: [String]?
    public var exposeHeaders: [String]?
    public var maxAgeSeconds: Int?
    
    enum CodingKeys: String, CodingKey {
        case allowedOrigins = "allowed"
        case allowedMethods = "methods"
        case allowedHeaders = "headers"
        case exposeHeaders = "exposeHeaders"
        case maxAgeSeconds = "maxAgeSeconds"
    }
    
    public init(allowedOrigins: [String], allowedMethods: [String], allowedHeaders: [String]? = nil, exposeHeaders: [String]? = nil, maxAgeSeconds: Int? = 3600) {
        self.allowedOrigins = allowedOrigins
        self.allowedMethods = allowedMethods
        self.allowedHeaders = allowedHeaders
        self.exposeHeaders = exposeHeaders
        self.maxAgeSeconds = maxAgeSeconds
    }
    
    public static let placeholders: [R2CORSRule] = [
        R2CORSRule(allowedOrigins: ["*"], allowedMethods: ["GET", "HEAD"], allowedHeaders: ["*"], maxAgeSeconds: 3600)
    ]
}

// MARK: - Worker Zone Route Model

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

// MARK: - Cloudflare Tunnel (Zero Trust) Models

public struct CFTunnel: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let status: String?
    public let createdAt: String?
    public let deletedAt: String?
    public let tunnelType: String?
    public let remoteConfig: Bool?
    public let connections: [TunnelConnection]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, status
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
        case tunnelType = "tunnel_type"
        case remoteConfig = "remote_config"
        case connections
    }
    
    public var isHealthy: Bool {
        status?.lowercased() == "healthy" || status?.lowercased() == "active"
    }
    
    public init(id: String, name: String, status: String? = "healthy", createdAt: String? = "2024-01-01T00:00:00Z", connections: [TunnelConnection]? = nil) {
        self.id = id
        self.name = name
        self.status = status
        self.createdAt = createdAt
        self.deletedAt = nil
        self.tunnelType = "cfd_tunnel"
        self.remoteConfig = true
        self.connections = connections
    }
    
    public static let placeholders: [CFTunnel] = (0..<5).map { idx in
        CFTunnel(id: "tunnel-uuid-\(idx + 1)-abcd", name: "edge-gateway-\(idx + 1)", status: "healthy")
    }
}

public struct TunnelConnection: Codable, Identifiable, Equatable {
    public var id: String { clientId ?? UUID().uuidString }
    public let clientId: String?
    public let version: String?
    public let arch: String?
    public let originIp: String?
    public let coloName: String?
    public let isPendingReconnect: Bool?
    public let openedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case version, arch
        case originIp = "origin_ip"
        case coloName = "colo_name"
        case isPendingReconnect = "is_pending_reconnect"
        case openedAt = "opened_at"
    }
}

public struct TunnelIngressRule: Codable, Identifiable, Equatable {
    public var id: String { "\(hostname ?? "")-\(path ?? "")-\(service ?? "")" }
    public let hostname: String?
    public let path: String?
    public let service: String?
}

// MARK: - Network Diagnostic Models (DoH / DNS Dig, HTTP & SSL)

public struct DNSAnswerItem: Identifiable, Equatable {
    public let id = UUID()
    public let name: String
    public let typeName: String
    public let ttl: Int
    public let data: String
    
    public init(name: String, typeName: String, ttl: Int, data: String) {
        self.name = name
        self.typeName = typeName
        self.ttl = ttl
        self.data = data
    }
    
    public static let placeholders: [DNSAnswerItem] = [
        DNSAnswerItem(name: "example.com", typeName: "A", ttl: 300, data: "93.184.216.34"),
        DNSAnswerItem(name: "example.com", typeName: "AAAA", ttl: 300, data: "2606:2800:220:1:248:1893:25c8:1946")
    ]
}

public struct DNSLookupResult: Equatable {
    public let questionName: String
    public let questionType: String
    public let status: Int
    public let answers: [DNSAnswerItem]
    public let server: String
    public let latencyMs: Double
}

public struct HTTPHeaderItem: Identifiable, Equatable {
    public let id = UUID()
    public let key: String
    public let value: String
    
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
    
    public static let tracePlaceholders: [HTTPHeaderItem] = [
        HTTPHeaderItem(key: "colo", value: "SFO"),
        HTTPHeaderItem(key: "ip", value: "198.51.100.42"),
        HTTPHeaderItem(key: "loc", value: "US"),
        HTTPHeaderItem(key: "warp", value: "plus"),
        HTTPHeaderItem(key: "gateway", value: "off"),
        HTTPHeaderItem(key: "kex", value: "X25519")
    ]
}

public struct HTTPInspectionResult: Equatable {
    public let url: String
    public let statusCode: Int
    public let statusText: String
    public let headers: [HTTPHeaderItem]
    public let cfRay: String?
    public let cfCacheStatus: String?
    public let server: String?
    public let durationMs: Double
    
    public init(url: String, statusCode: Int, statusText: String, headers: [HTTPHeaderItem], cfRay: String? = nil, cfCacheStatus: String? = nil, server: String? = nil, durationMs: Double) {
        self.url = url
        self.statusCode = statusCode
        self.statusText = statusText
        self.headers = headers
        self.cfRay = cfRay
        self.cfCacheStatus = cfCacheStatus
        self.server = server
        self.durationMs = durationMs
    }
    
    public static let placeholder = HTTPInspectionResult(
        url: "https://example.com",
        statusCode: 200,
        statusText: "OK",
        headers: [
            HTTPHeaderItem(key: "content-type", value: "text/html; charset=UTF-8"),
            HTTPHeaderItem(key: "server", value: "cloudflare"),
            HTTPHeaderItem(key: "cf-cache-status", value: "HIT"),
            HTTPHeaderItem(key: "cf-ray", value: "89a12bc34de56789-SJC")
        ],
        cfRay: "89a12bc34de56789-SJC",
        cfCacheStatus: "HIT",
        server: "cloudflare",
        durationMs: 42.5
    )
}

public struct SSLChainResult: Equatable {
    public let hostname: String
    public let isValid: Bool
    public let issuer: String
    public let subject: String
    public let validFrom: Date?
    public let validTo: Date?
    public let daysRemaining: Int
    public let sans: [String]
    public let protocolVersion: String?
    public let errorDescription: String?
    
    public init(hostname: String, isValid: Bool, issuer: String, subject: String, validFrom: Date? = nil, validTo: Date? = nil, daysRemaining: Int = 90, sans: [String] = [], protocolVersion: String? = nil, errorDescription: String? = nil) {
        self.hostname = hostname
        self.isValid = isValid
        self.issuer = issuer
        self.subject = subject
        self.validFrom = validFrom
        self.validTo = validTo
        self.daysRemaining = daysRemaining
        self.sans = sans
        self.protocolVersion = protocolVersion
        self.errorDescription = errorDescription
    }
    
    public static let placeholder = SSLChainResult(
        hostname: "example.com",
        isValid: true,
        issuer: "GTS CA 1P5 (Google Trust Services)",
        subject: "CN=example.com",
        validFrom: Date(timeIntervalSince1970: 1700000000),
        validTo: Date(timeIntervalSince1970: 1800000000),
        daysRemaining: 84,
        sans: ["example.com", "*.example.com"],
        protocolVersion: "TLSv1.3"
    )
}

public struct IPLookupResult: Equatable {
    public let query: String
    public let ip: String
    public let asn: String?
    public let org: String?
    public let country: String?
    public let countryCode: String?
    public let city: String?
    public let region: String?
    public let timezone: String?
    public let latitude: Double?
    public let longitude: Double?
    
    public init(query: String, ip: String, asn: String? = nil, org: String? = nil, country: String? = nil, countryCode: String? = nil, city: String? = nil, region: String? = nil, timezone: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.query = query
        self.ip = ip
        self.asn = asn
        self.org = org
        self.country = country
        self.countryCode = countryCode
        self.city = city
        self.region = region
        self.timezone = timezone
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public static let placeholder = IPLookupResult(
        query: "1.1.1.1",
        ip: "1.1.1.1",
        asn: "AS13335",
        org: "Cloudflare, Inc.",
        country: "United States",
        countryCode: "US",
        city: "San Francisco",
        region: "California",
        timezone: "America/Los_Angeles",
        latitude: 37.7749,
        longitude: -122.4194
    )
}

public struct D1TableColumn: Identifiable, Equatable {
    public var id: String { name }
    public let cid: Int
    public let name: String
    public let type: String
    public let notnull: Int
    public let dflt_value: String?
    public let pk: Int
}

// MARK: - Audit Logs Models

public struct AuditLog: Codable, Identifiable, Equatable {
    public let id: String
    public let actor: AuditActor?
    public let action: AuditAction?
    public let when: String?
    public let resource: AuditResource?
    
    public init(id: String, actor: AuditActor?, action: AuditAction?, when: String?, resource: AuditResource? = nil) {
        self.id = id
        self.actor = actor
        self.action = action
        self.when = when
        self.resource = resource
    }
    
    public static let placeholders: [AuditLog] = [
        AuditLog(id: "audit_1", actor: AuditActor(id: "1", email: "admin@example.com", type: "user", ip: "192.0.2.1"), action: AuditAction(type: "zone.dns_record.create", result: true), when: "2024-01-01T12:00:00Z"),
        AuditLog(id: "audit_2", actor: AuditActor(id: "2", email: "dev@example.com", type: "user", ip: "198.51.100.2"), action: AuditAction(type: "worker.script.update", result: true), when: "2024-01-01T11:45:00Z"),
        AuditLog(id: "audit_3", actor: AuditActor(id: "3", email: "system@api", type: "api_key", ip: "203.0.113.1"), action: AuditAction(type: "waf.rule.delete", result: true), when: "2024-01-01T10:30:00Z")
    ]
}

public struct AuditActor: Codable, Equatable {
    public let id: String?
    public let email: String?
    public let type: String?
    public let ip: String?
}

public struct AuditAction: Codable, Equatable {
    public let type: String?
    public let result: Bool?
}

public struct AuditResource: Codable, Equatable {
    public let type: String?
    public let id: String?
}

// MARK: - Turnstile Models

public struct TurnstileWidget: Codable, Identifiable, Equatable {
    public var id: String { sitekey }
    public let sitekey: String
    public let name: String
    public let mode: String?
    public let domains: [String]?
    public let secret: String?
    public let createdOn: String?
    public let modifiedOn: String?
    
    enum CodingKeys: String, CodingKey {
        case sitekey, name, mode, domains, secret
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
    }
    
    public init(
        sitekey: String,
        name: String,
        mode: String? = "managed",
        domains: [String]? = ["example.com"],
        secret: String? = nil,
        createdOn: String? = "2024-01-01T00:00:00Z",
        modifiedOn: String? = "2024-01-01T00:00:00Z"
    ) {
        self.sitekey = sitekey
        self.name = name
        self.mode = mode
        self.domains = domains
        self.secret = secret
        self.createdOn = createdOn
        self.modifiedOn = modifiedOn
    }
    
    public static let placeholders: [TurnstileWidget] = (0..<4).map { idx in
        TurnstileWidget(sitekey: "0x4AAAAAAAXyZ\(idx + 1)", name: "Login Captcha Widget \(idx + 1)")
    }
}

public struct TurnstileCreateInput: Codable {
    public let name: String
    public let domains: [String]
    public let mode: String
    public let region: String?
    
    public init(name: String, domains: [String], mode: String = "managed", region: String? = "world") {
        self.name = name
        self.domains = domains
        self.mode = mode
        self.region = region
    }
}

public struct TurnstileUpdateInput: Codable {
    public let name: String
    public let domains: [String]
    public let mode: String
    
    public init(name: String, domains: [String], mode: String) {
        self.name = name
        self.domains = domains
        self.mode = mode
    }
}

// MARK: - AI Gateway Models

public struct AIGateway: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String?
    public let collectLogs: Bool?
    public let createdOn: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case collectLogs = "collect_logs"
        case createdOn = "created_on"
    }
    
    public init(id: String, name: String? = nil, collectLogs: Bool? = true, createdOn: String? = "2024-01-01T00:00:00Z") {
        self.id = id
        self.name = name
        self.collectLogs = collectLogs
        self.createdOn = createdOn
    }
    
    public static let placeholders: [AIGateway] = (0..<4).map { idx in
        AIGateway(id: "ai-gateway-\(idx + 1)")
    }
}

// MARK: - Workers AI Models

public struct AIModel: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String?
    public let description: String?
    public let task: AIModelTask?
    
    public init(id: String, name: String?, description: String?, task: AIModelTask? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.task = task
    }
    
    public static let placeholders: [AIModel] = [
        AIModel(id: "@cf/meta/llama-3-8b-instruct", name: "@cf/meta/llama-3-8b-instruct", description: "Generation 3 of Llama, trained on 8B tokens.", task: AIModelTask(id: "text-generation", name: "Text Generation", description: nil)),
        AIModel(id: "@cf/stabilityai/stable-diffusion-xl-base-1.0", name: "@cf/stabilityai/stable-diffusion-xl-base-1.0", description: "Diffusion-based text-to-image generative model.", task: AIModelTask(id: "text-to-image", name: "Text-to-Image", description: nil)),
        AIModel(id: "@cf/baai/bge-large-en-v1.5", name: "@cf/baai/bge-large-en-v1.5", description: "Embedding model for text similarity and search.", task: AIModelTask(id: "text-embeddings", name: "Text Embeddings", description: nil))
    ]
    
    public var modelPath: String {
        if let name = name, !name.isEmpty, name.contains("/") {
            return name
        }
        if id.contains("/") {
            return id
        }
        return name ?? id
    }
    
    public var shortName: String {
        let raw = modelPath
        return raw.split(separator: "/").last.map(String.init) ?? raw
    }
    
    public var taskName: String {
        task?.name ?? "General AI"
    }
}

public struct AIModelTask: Codable, Equatable {
    public let id: String?
    public let name: String?
    public let description: String?
}

// MARK: - SSL Diagnostic Models

public struct SSLCertDetails: Identifiable, Equatable {
    public var id: String { commonName + (issuer ?? "") }
    public let commonName: String
    public let issuer: String?
    public let validityDaysRemaining: Int?
    public let protocolNegotiated: String?
    public let chainCount: Int
    public let isCloudflareEdge: Bool
    public let validFrom: String?
    public let validUntil: String?
    public let sans: [String]
    
    public init(commonName: String, issuer: String? = nil, validityDaysRemaining: Int? = 90, protocolNegotiated: String? = "TLSv1.3", chainCount: Int = 2, isCloudflareEdge: Bool = true, validFrom: String? = nil, validUntil: String? = nil, sans: [String] = []) {
        self.commonName = commonName
        self.issuer = issuer
        self.validityDaysRemaining = validityDaysRemaining
        self.protocolNegotiated = protocolNegotiated
        self.chainCount = chainCount
        self.isCloudflareEdge = isCloudflareEdge
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.sans = sans
    }
    
    public static let placeholder = SSLCertDetails(
        commonName: "cloudflare.com",
        issuer: "GTS CA 1P5 (Google Trust Services)",
        validityDaysRemaining: 84,
        protocolNegotiated: "TLSv1.3",
        chainCount: 2,
        isCloudflareEdge: true,
        validFrom: "2024-01-01 00:00:00 UTC",
        validUntil: "2024-12-31 23:59:59 UTC",
        sans: ["cloudflare.com", "*.cloudflare.com"]
    )
}

// MARK: - Redirect Rules & Snippets

public struct RedirectRuleItem: Codable, Identifiable, Equatable {
    public let id: String
    public let description: String?
    public let expression: String?
    public let targetUrl: String?
    public let statusCode: Int?
    public let preserveQueryString: Bool?
    public let enabled: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, description, expression, enabled
        case actionParameters = "action_parameters"
        case targetUrl = "target_url"
        case statusCode = "status_code"
    }
    
    private struct ActionParams: Codable {
        let fromValue: FromValue?
        enum CodingKeys: String, CodingKey {
            case fromValue = "from_value"
        }
    }
    
    private struct FromValue: Codable {
        let statusCode: Int?
        let targetUrl: TargetUrlObj?
        let preserveQueryString: Bool?
        
        enum CodingKeys: String, CodingKey {
            case statusCode = "status_code"
            case targetUrl = "target_url"
            case preserveQueryString = "preserve_query_string"
        }
    }
    
    private struct TargetUrlObj: Codable {
        let value: String?
        let expression: String?
    }
    
    public init(id: String, description: String?, expression: String?, targetUrl: String?, statusCode: Int?, preserveQueryString: Bool? = nil, enabled: Bool? = true) {
        self.id = id
        self.description = description
        self.expression = expression
        self.targetUrl = targetUrl
        self.statusCode = statusCode
        self.preserveQueryString = preserveQueryString
        self.enabled = enabled
    }
    
    public static let placeholders: [RedirectRuleItem] = [
        RedirectRuleItem(id: "redir_1", description: "Redirect HTTP to HTTPS", expression: "http.request.uri.path eq \"/old-docs\"", targetUrl: "https://docs.example.com/v2", statusCode: 301),
        RedirectRuleItem(id: "redir_2", description: "Forward Blog traffic", expression: "http.host eq \"blog.example.com\"", targetUrl: "https://example.com/blog", statusCode: 302)
    ]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.expression = try container.decodeIfPresent(String.self, forKey: .expression)
        self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)
        
        if let params = try container.decodeIfPresent(ActionParams.self, forKey: .actionParameters),
           let fromVal = params.fromValue {
            self.statusCode = fromVal.statusCode
            self.targetUrl = fromVal.targetUrl?.value ?? fromVal.targetUrl?.expression
            self.preserveQueryString = fromVal.preserveQueryString
        } else {
            self.targetUrl = try container.decodeIfPresent(String.self, forKey: .targetUrl)
            self.statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode)
            self.preserveQueryString = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(expression, forKey: .expression)
        try container.encodeIfPresent(enabled, forKey: .enabled)
        try container.encodeIfPresent(targetUrl, forKey: .targetUrl)
        try container.encodeIfPresent(statusCode, forKey: .statusCode)
    }
}

public struct SnippetItem: Codable, Identifiable, Equatable {
    public var id: String { snippet_name }
    public let snippet_name: String
    public let modifiedOn: String?
    public let createdOn: String?
    
    enum CodingKeys: String, CodingKey {
        case snippet_name
        case modifiedOn = "modified_on"
        case createdOn = "created_on"
    }
    
    public init(snippet_name: String, modifiedOn: String? = nil, createdOn: String? = nil) {
        self.snippet_name = snippet_name
        self.modifiedOn = modifiedOn
        self.createdOn = createdOn
    }
    
    public static let placeholders: [SnippetItem] = [
        SnippetItem(snippet_name: "add_security_headers", modifiedOn: "2024-01-01T00:00:00Z"),
        SnippetItem(snippet_name: "normalize_uri_path", modifiedOn: "2024-01-01T00:00:00Z")
    ]
}

// MARK: - Cloudflare Queues Models

public struct CFQueue: Codable, Identifiable, Equatable {
    public var id: String { queueId ?? queueName }
    public let queueId: String?
    public let queueName: String
    public let createdOn: String?
    public let modifiedOn: String?
    public let settings: CFQueueSettings?
    public let producers: [CFQueueProducer]?
    public let consumers: [CFQueueConsumer]?
    
    enum CodingKeys: String, CodingKey {
        case queueId = "queue_id"
        case queueName = "queue_name"
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
        case settings, producers, consumers
    }
    
    public init(queueId: String?, queueName: String, createdOn: String? = nil, modifiedOn: String? = nil, settings: CFQueueSettings? = nil, producers: [CFQueueProducer]? = nil, consumers: [CFQueueConsumer]? = nil) {
        self.queueId = queueId
        self.queueName = queueName
        self.createdOn = createdOn
        self.modifiedOn = modifiedOn
        self.settings = settings
        self.producers = producers
        self.consumers = consumers
    }
    
    public static let placeholders: [CFQueue] = [
        CFQueue(queueId: "q_1", queueName: "auth-events-queue", createdOn: "2024-01-01T00:00:00Z"),
        CFQueue(queueId: "q_2", queueName: "email-notifications-queue", createdOn: "2024-01-01T00:00:00Z")
    ]
}

public struct CFQueueSettings: Codable, Equatable {
    public let deliveryDelay: Int?
    public let messageRetentionPeriod: Int?
    public let deliveryPaused: Bool?
    
    enum CodingKeys: String, CodingKey {
        case deliveryDelay = "delivery_delay"
        case messageRetentionPeriod = "message_retention_period"
        case deliveryPaused = "delivery_paused"
    }
}

public struct CFQueueProducer: Codable, Equatable, Identifiable {
    public var id: String { script ?? "\(service ?? "")-\(environment ?? "")" }
    public let service: String?
    public let environment: String?
    public let script: String?
}

public struct CFQueueConsumer: Codable, Equatable, Identifiable {
    public var id: String { scriptName ?? "\(service ?? "")-\(environment ?? "")" }
    public let service: String?
    public let environment: String?
    public let scriptName: String?
    public let settings: CFQueueConsumerSettings?
    
    enum CodingKeys: String, CodingKey {
        case service, environment
        case scriptName = "script_name"
        case settings
    }
}

public struct CFQueueConsumerSettings: Codable, Equatable {
    public let batchSize: Int?
    public let maxBatchTimeout: Int?
    public let maxRetries: Int?
    public let maxWaitTimeMs: Int?
    public let retryDelay: Int?
    
    enum CodingKeys: String, CodingKey {
        case batchSize = "batch_size"
        case maxBatchTimeout = "max_batch_timeout"
        case maxRetries = "max_retries"
        case maxWaitTimeMs = "max_wait_time_ms"
        case retryDelay = "retry_delay"
    }
}

public struct CFQueueCreate: Codable {
    public let queueName: String
    enum CodingKeys: String, CodingKey {
        case queueName = "queue_name"
    }
    public init(queueName: String) { self.queueName = queueName }
}

public struct CFQueueUpdate: Codable {
    public let queueName: String?
    public let deliveryDelay: Int?
    public let messageRetentionPeriod: Int?
    public let deliveryPaused: Bool?
    
    enum CodingKeys: String, CodingKey {
        case queueName = "queue_name"
        case deliveryDelay = "delivery_delay"
        case messageRetentionPeriod = "message_retention_period"
        case deliveryPaused = "delivery_paused"
    }
    public init(queueName: String? = nil, deliveryDelay: Int? = nil, messageRetentionPeriod: Int? = nil, deliveryPaused: Bool? = nil) {
        self.queueName = queueName
        self.deliveryDelay = deliveryDelay
        self.messageRetentionPeriod = messageRetentionPeriod
        self.deliveryPaused = deliveryPaused
    }
}

public struct CFQueuePurge: Codable {
    public let deleteMessagesPermanently: Bool
    enum CodingKeys: String, CodingKey {
        case deleteMessagesPermanently = "delete_messages_permanently"
    }
    public init(deleteMessagesPermanently: Bool = true) {
        self.deleteMessagesPermanently = deleteMessagesPermanently
    }
}

// MARK: - Durable Objects Models

public struct DurableObjectNamespace: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let script: String?
    public let `class`: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, script, `class`
    }
    
    public init(id: String, name: String, script: String? = nil, class: String? = nil) {
        self.id = id
        self.name = name
        self.script = script
        self.class = `class`
    }
    
    public static let placeholders: [DurableObjectNamespace] = [
        DurableObjectNamespace(id: "do_1", name: "UserSessionCoordinator", script: "auth-worker", class: "SessionCoordinator"),
        DurableObjectNamespace(id: "do_2", name: "RoomPresenceManager", script: "chat-worker", class: "RoomPresence")
    ]
}

public struct DurableObjectInstance: Codable, Identifiable, Equatable {
    public let id: String
    public let hasStoredData: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case hasStoredData = "hasStoredData"
    }
}

// MARK: - Hyperdrive Models

public struct HyperdriveConfig: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let origin: HyperdriveOrigin?
    public let caching: HyperdriveCaching?
    public let createdOn: String?
    public let modifiedOn: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, origin, caching
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
    }
    
    public init(id: String, name: String, origin: HyperdriveOrigin? = nil, caching: HyperdriveCaching? = nil, createdOn: String? = nil, modifiedOn: String? = nil) {
        self.id = id
        self.name = name
        self.origin = origin
        self.caching = caching
        self.createdOn = createdOn
        self.modifiedOn = modifiedOn
    }
    
    public static let placeholders: [HyperdriveConfig] = [
        HyperdriveConfig(id: "hd_1", name: "prod-postgres-hyperdrive", origin: HyperdriveOrigin(host: "db.aws.example.com", port: 5432, database: "users", user: "app", scheme: "postgres")),
        HyperdriveConfig(id: "hd_2", name: "staging-postgres-accelerator", origin: HyperdriveOrigin(host: "staging-db.example.com", port: 5432, database: "staging", user: "app", scheme: "postgres"))
    ]
}

public struct HyperdriveOrigin: Codable, Equatable {
    public let host: String?
    public let port: Int?
    public let database: String?
    public let user: String?
    public let scheme: String?
}

public struct HyperdriveCaching: Codable, Equatable {
    public let disabled: Bool?
    public let maxAge: Int?
    public let staleWhileRevalidate: Int?
    
    enum CodingKeys: String, CodingKey {
        case disabled
        case maxAge = "max_age"
        case staleWhileRevalidate = "stale_while_revalidate"
    }
}

public struct HyperdriveCreate: Codable {
    public let name: String
    public let origin: HyperdriveOriginInput
    public let caching: HyperdriveCaching?
    
    public init(name: String, origin: HyperdriveOriginInput, caching: HyperdriveCaching? = nil) {
        self.name = name
        self.origin = origin
        self.caching = caching
    }
}

public struct HyperdriveOriginInput: Codable {
    public let host: String
    public let port: Int
    public let database: String
    public let user: String
    public let password: String
    public let scheme: String
    
    public init(host: String, port: Int, database: String, user: String, password: String, scheme: String = "postgres") {
        self.host = host
        self.port = port
        self.database = database
        self.user = user
        self.password = password
        self.scheme = scheme
    }
}

public struct HyperdrivePatch: Codable {
    public let name: String?
    public let origin: HyperdriveOriginInput?
    public let caching: HyperdriveCaching?
    
    public init(name: String? = nil, origin: HyperdriveOriginInput? = nil, caching: HyperdriveCaching? = nil) {
        self.name = name
        self.origin = origin
        self.caching = caching
    }
}

// MARK: - Zero Trust Models

public struct AccessApp: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let domain: String
    public let type: String?
    public let aud: String?
    public let createdAt: String?
    public let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, domain, type, aud
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(id: String, name: String, domain: String, type: String? = "self_hosted", aud: String? = nil, createdAt: String? = nil, updatedAt: String? = nil) {
        self.id = id
        self.name = name
        self.domain = domain
        self.type = type
        self.aud = aud
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public static let placeholders: [AccessApp] = [
        AccessApp(id: "app_1", name: "Internal Admin Dashboard", domain: "admin.internal.net", type: "self_hosted"),
        AccessApp(id: "app_2", name: "Production Grafana", domain: "grafana.internal.net", type: "self_hosted"),
        AccessApp(id: "app_3", name: "Staging SSH Gateway", domain: "ssh.staging.internal.net", type: "ssh")
    ]
}

public struct AccessPolicy: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let decision: String
    public let precedence: Int?
    public let createdAt: String?
    public let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, decision, precedence
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct GatewayRule: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let action: String
    public let enabled: Bool
    public let filters: [String]?
    public let traffic: String?
    public let identity: String?
    public let precedence: Int?
    public let createdAt: String?
    public let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, action, enabled, filters, traffic, identity, precedence
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(id: String, name: String, action: String = "block", enabled: Bool = true, traffic: String? = "dns.security.category in {1}", precedence: Int? = 1) {
        self.id = id
        self.name = name
        self.action = action
        self.enabled = enabled
        self.filters = nil
        self.traffic = traffic
        self.identity = nil
        self.precedence = precedence
        self.createdAt = nil
        self.updatedAt = nil
    }
    
    public static let placeholders: [GatewayRule] = [
        GatewayRule(id: "gw_1", name: "Block Malware & Phishing", action: "block", enabled: true, traffic: "dns.security.category in {1 2 3}"),
        GatewayRule(id: "gw_2", name: "Isolate Social Media", action: "isolate", enabled: true, traffic: "http.request.host in {\"facebook.com\" \"twitter.com\"}")
    ]
}

// MARK: - Bulk Redirects Models

public struct RedirectList: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let description: String?
    public let kind: String
    public let count: Int?
    public let createdOn: String?
    public let modifiedOn: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, kind, count
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
    }
    
    public init(id: String, name: String, description: String? = nil, kind: String = "redirect", count: Int? = 12, createdOn: String? = nil, modifiedOn: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.kind = kind
        self.count = count
        self.createdOn = createdOn
        self.modifiedOn = modifiedOn
    }
    
    public static let placeholders: [RedirectList] = [
        RedirectList(id: "list_1", name: "marketing-campaign-redirects", description: "URL shortlinks and promo campaign redirects", count: 24),
        RedirectList(id: "list_2", name: "legacy-v1-api-redirects", description: "Permanent redirects for deprecated REST endpoints", count: 88)
    ]
}

public struct RedirectListItem: Codable, Identifiable, Equatable {
    public let id: String
    public let redirect: RedirectItemDetail
    public let createdOn: String?
    public let modifiedOn: String?
    
    enum CodingKeys: String, CodingKey {
        case id, redirect
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
    }
}

public struct RedirectItemDetail: Codable, Equatable {
    public let sourceUrl: String
    public let targetUrl: String
    public let statusCode: Int?
    public let preserveQueryString: Bool?
    public let includeSubdomains: Bool?
    public let subpathMatching: Bool?
    public let preservePathSuffix: Bool?
    
    enum CodingKeys: String, CodingKey {
        case sourceUrl = "source_url"
        case targetUrl = "target_url"
        case statusCode = "status_code"
        case preserveQueryString = "preserve_query_string"
        case includeSubdomains = "include_subdomains"
        case subpathMatching = "subpath_matching"
        case preservePathSuffix = "preserve_path_suffix"
    }
}

public struct BulkOperationRef: Codable {
    public let operationId: String
    enum CodingKeys: String, CodingKey {
        case operationId = "operation_id"
    }
}

public struct BulkOperation: Codable {
    public let id: String
    public let status: String
    public let error: String?
    public let completed: String?
}

// MARK: - Cloudflare Alerting Models

public struct AlertingAvailableType: Codable, Identifiable, Equatable {
    public var id: String { type }
    public let type: String
    public let displayName: String?
    public let description: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case displayName = "display_name"
        case description
    }
}

public struct AlertingWebhookDestination: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String?
    public let url: String?
    public let type: String?
}

public struct AlertingPolicy: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String?
    public let description: String?
    public let enabled: Bool?
    public let alertType: String?
    public let created: String?
    public let modified: String?
    
    public var isEnabled: Bool {
        enabled ?? true
    }
    
    public var displayName: String {
        name ?? alertType ?? id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, enabled
        case alertType = "alert_type"
        case created, modified
    }
    
    public init(id: String, name: String?, description: String? = nil, enabled: Bool? = true, alertType: String? = nil, created: String? = nil, modified: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.enabled = enabled
        self.alertType = alertType
        self.created = created
        self.modified = modified
    }
    
    public static let placeholders: [AlertingPolicy] = [
        AlertingPolicy(id: "pol_1", name: "High HTTP 5xx Error Rate Alert", description: "Notifies Ops team on Slack when origin errors exceed 5%", enabled: true, alertType: "http_alert_origin_error_rate"),
        AlertingPolicy(id: "pol_2", name: "DDoS Mitigation Triggered", description: "Immediate paging when volumetric DDoS is detected", enabled: true, alertType: "dos_attack_l7")
    ]
}



