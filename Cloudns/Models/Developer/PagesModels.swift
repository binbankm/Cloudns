import Foundation

// MARK: - Pages Models

public struct PagesProject: Codable, Identifiable, Equatable, Sendable {
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

public struct PagesProjectSource: Codable, Equatable, Sendable {
    public let type: String?
    public let config: PagesProjectSourceConfig?
}

public struct PagesProjectSourceConfig: Codable, Equatable, Sendable {
    public let repoName: String?
    public let owner: String?
    public let productionBranch: String?
    
    enum CodingKeys: String, CodingKey {
        case repoName = "repo_name"
        case owner
        case productionBranch = "production_branch"
    }
}

public struct PagesDeploymentConfigs: Codable, Equatable, Sendable {
    public let production: PagesEnvConfig?
    public let preview: PagesEnvConfig?
}

public struct PagesEnvConfig: Codable, Equatable, Sendable {
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

public struct PagesEnvVarValue: Codable, Equatable, Sendable {
    public let value: String?
    public let type: String?
    
    public var isSecret: Bool { type == "secret_text" }
}

public struct PagesD1Binding: Codable, Equatable, Sendable {
    public let id: String?
}

public struct PagesKVBinding: Codable, Equatable, Sendable {
    public let namespaceId: String?
    enum CodingKeys: String, CodingKey {
        case namespaceId = "namespace_id"
    }
}

public struct PagesR2Binding: Codable, Equatable, Sendable {
    public let name: String?
}

public struct PagesAIBinding: Codable, Equatable, Sendable {
    public let projectId: String?
    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
    }
}

public struct PagesQueueBinding: Codable, Equatable, Sendable {
    public let name: String?
}

public struct PagesBuildConfig: Codable, Equatable, Sendable {
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

public struct PagesDomain: Codable, Identifiable, Equatable, Sendable {
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

public struct PagesDeployment: Codable, Identifiable, Equatable, Sendable {
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

public struct PagesDeploymentLog: Codable, Identifiable, Equatable, Sendable {
    public var id: String { "\(ts)-\(line.hashValue)" }
    public let ts: String
    public let line: String
}

public struct PagesDeploymentLogsResult: Codable, Sendable {
    public let total: Int?
    public let data: [PagesDeploymentLog]?
}

public struct PagesStage: Codable, Equatable, Sendable {
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

public struct PagesTrigger: Codable, Equatable, Sendable {
    public let type: String?
    public let metadata: PagesTriggerMetadata?
}

public struct PagesTriggerMetadata: Codable, Equatable, Sendable {
    public let branch: String?
    public let commitHash: String?
    public let commitMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case branch
        case commitHash = "commit_hash"
        case commitMessage = "commit_message"
    }
}
