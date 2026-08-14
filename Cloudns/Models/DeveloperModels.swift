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
    
    enum CodingKeys: String, CodingKey {
        case name, type
        case namespaceId = "namespace_id"
        case bucketName = "bucket_name"
        case databaseId = "database_id"
        case text
    }
}

public struct WorkerSecret: Codable, Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let type: String
    public let modifiedOn: String?
    
    enum CodingKeys: String, CodingKey {
        case name, type
        case modifiedOn = "modified_on"
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
    
    enum CodingKeys: String, CodingKey {
        case envVars = "env_vars"
        case compatibilityDate = "compatibility_date"
        case compatibilityFlags = "compatibility_flags"
    }
}

public struct PagesEnvVarValue: Codable, Equatable {
    public let value: String
    public let type: String?
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
}

public struct KVKey: Codable, Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let expiration: Int?
    public let metadata: String?
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
    public let createdOn: String?
    public let modifiedOn: String?
    
    enum CodingKeys: String, CodingKey {
        case sitekey, name, mode, domains
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
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
}

// MARK: - Workers AI Models

public struct AIModel: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String?
    public let description: String?
    public let task: AIModelTask?
    
    public var shortName: String {
        name ?? id.split(separator: "/").last.map(String.init) ?? id
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
}

// MARK: - Redirect Rules & Snippets

public struct RedirectRuleItem: Codable, Identifiable, Equatable {
    public let id: String
    public let description: String?
    public let expression: String?
    public let targetUrl: String?
    public let statusCode: Int?
    public let enabled: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, description, expression, enabled
        case targetUrl = "target_url"
        case statusCode = "status_code"
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
}



