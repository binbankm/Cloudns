import Foundation

/// Cloudflare Pages 项目与部署领域服务抽象协议
protocol PagesServiceProtocol: Sendable {
    func getPagesProjects(accountId: String) async throws -> [PagesProject]
    func listPagesProjects(accountId: String) async throws -> [PagesProject]
    func createPagesProject(accountId: String, name: String, productionBranch: String) async throws -> PagesProject
    func deletePagesProject(accountId: String, projectName: String) async throws
    func updatePagesProject(accountId: String, projectName: String, buildCommand: String?, destinationDir: String?, rootDir: String?, productionBranch: String?, buildConfig: PagesBuildConfig?, envConfig: PagesEnvConfig?) async throws
    func getPagesDeployments(accountId: String, projectName: String) async throws -> [PagesDeployment]
    func getPagesDomains(accountId: String, projectName: String) async throws -> [PagesDomain]
    func addPagesDomain(accountId: String, projectName: String, domain: String) async throws
    func deletePagesDomain(accountId: String, projectName: String, domain: String) async throws
    func rollbackPagesDeployment(accountId: String, projectName: String, deploymentId: String) async throws
    func retryPagesDeployment(accountId: String, projectName: String, deploymentId: String) async throws
    func deletePagesDeployment(accountId: String, projectName: String, deploymentId: String) async throws
    func getPagesDeploymentLogs(accountId: String, projectName: String, deploymentId: String) async throws -> [PagesDeploymentLog]
    func updatePagesEnvVars(accountId: String, projectName: String, environment: String, envVars: [String: PagesEnvVarValue]) async throws
    func updatePagesResourceBindings(accountId: String, projectName: String, environment: String, kvNamespaces: [String: PagesKVBinding]?, d1Databases: [String: PagesD1Binding]?, r2Buckets: [String: PagesR2Binding]?, aiBindings: [String: PagesAIBinding]?) async throws
}

/// 统一的 Cloudflare Pages 项目与部署领域服务
final class PagesService: PagesServiceProtocol {
    static let shared = PagesService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func getPagesProjects(accountId: String) async throws -> [PagesProject] {
        try await listPagesProjects(accountId: accountId)
    }
    
    func listPagesProjects(accountId: String) async throws -> [PagesProject] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/pages/projects")
        let (projects, _): ([PagesProject]?, ResultInfo?) = try await client.performRequest(request)
        return projects ?? []
    }
    
    func createPagesProject(accountId: String, name: String, productionBranch: String = "main") async throws -> PagesProject {
        let payload: [String: Any] = ["name": name, "production_branch": productionBranch]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/pages/projects", method: "POST", body: data)
        let (project, _): (PagesProject?, ResultInfo?) = try await client.performRequest(request)
        guard let p = project else { throw APIError.cloudflareError("Failed to create pages project") }
        return p
    }
    
    func deletePagesProject(accountId: String, projectName: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/pages/projects/\(projectName)", method: "DELETE")
        struct DeleteRes: Codable { let id: String? }
        let (_, _): (DeleteRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func updatePagesProject(
        accountId: String,
        projectName: String,
        buildCommand: String? = nil,
        destinationDir: String? = nil,
        rootDir: String? = nil,
        productionBranch: String? = nil,
        buildConfig: PagesBuildConfig? = nil,
        envConfig: PagesEnvConfig? = nil
    ) async throws {
        var payload: [String: Any] = [:]
        if let b = buildConfig {
            var bDict: [String: Any] = [:]
            if let cmd = b.buildCommand { bDict["build_command"] = cmd }
            if let dest = b.destinationDir { bDict["destination_dir"] = dest }
            if let root = b.rootDir { bDict["root_dir"] = root }
            payload["build_config"] = bDict
        } else if buildCommand != nil || destinationDir != nil || rootDir != nil {
            var bDict: [String: Any] = [:]
            if let cmd = buildCommand { bDict["build_command"] = cmd }
            if let dest = destinationDir { bDict["destination_dir"] = dest }
            if let root = rootDir { bDict["root_dir"] = root }
            payload["build_config"] = bDict
        }
        if let branch = productionBranch {
            payload["production_branch"] = branch
        }
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/pages/projects/\(projectName)", method: "PATCH", body: data)
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func getPagesDeployments(accountId: String, projectName: String) async throws -> [PagesDeployment] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/pages/projects/\(projectName)/deployments")
        let (deps, _): ([PagesDeployment]?, ResultInfo?) = try await client.performRequest(request)
        return deps ?? []
    }
    
    func getPagesDomains(accountId: String, projectName: String) async throws -> [PagesDomain] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/pages/projects/\(projectName)/domains")
        let (doms, _): ([PagesDomain]?, ResultInfo?) = try await client.performRequest(request)
        return doms ?? []
    }
    
    func addPagesDomain(accountId: String, projectName: String, domain: String) async throws {
        let payload: [String: Any] = ["name": domain]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/pages/projects/\(projectName)/domains", method: "POST", body: data)
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func deletePagesDomain(accountId: String, projectName: String, domain: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/pages/projects/\(projectName)/domains/\(domain)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func rollbackPagesDeployment(accountId: String, projectName: String, deploymentId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/pages/projects/\(projectName)/deployments/\(deploymentId)/rollback", method: "POST")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func retryPagesDeployment(accountId: String, projectName: String, deploymentId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/pages/projects/\(projectName)/deployments/\(deploymentId)/retry", method: "POST")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func deletePagesDeployment(accountId: String, projectName: String, deploymentId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/pages/projects/\(projectName)/deployments/\(deploymentId)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func getPagesDeploymentLogs(accountId: String, projectName: String, deploymentId: String) async throws -> [PagesDeploymentLog] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/pages/projects/\(projectName)/deployments/\(deploymentId)/history/logs")
        let (logs, _): (PagesDeploymentLogsResult?, ResultInfo?) = try await client.performRequest(request)
        return logs?.data ?? []
    }
    
    func updatePagesEnvVars(accountId: String, projectName: String, environment: String, envVars: [String: PagesEnvVarValue]) async throws {
        var envVarsDict: [String: Any] = [:]
        for (k, v) in envVars {
            var varDict: [String: Any] = ["type": v.type ?? (v.isSecret ? "secret_text" : "plain_text")]
            if let val = v.value { varDict["value"] = val }
            envVarsDict[k] = varDict
        }
        let payload: [String: Any] = [
            "deployment_configs": [
                environment: [
                    "env_vars": envVarsDict
                ]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/pages/projects/\(projectName)", method: "PATCH", body: data)
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func updatePagesResourceBindings(
        accountId: String,
        projectName: String,
        environment: String,
        kvNamespaces: [String: PagesKVBinding]? = nil,
        d1Databases: [String: PagesD1Binding]? = nil,
        r2Buckets: [String: PagesR2Binding]? = nil,
        aiBindings: [String: PagesAIBinding]? = nil
    ) async throws {
        var envConfigDict: [String: Any] = [:]
        if let kv = kvNamespaces {
            var kvDict: [String: Any] = [:]
            for (k, v) in kv {
                if let nsId = v.namespaceId { kvDict[k] = ["namespace_id": nsId] }
            }
            envConfigDict["kv_namespaces"] = kvDict
        }
        if let d1 = d1Databases {
            var d1Dict: [String: Any] = [:]
            for (k, v) in d1 {
                if let id = v.id { d1Dict[k] = ["id": id] }
            }
            envConfigDict["d1_databases"] = d1Dict
        }
        if let r2 = r2Buckets {
            var r2Dict: [String: Any] = [:]
            for (k, v) in r2 {
                if let name = v.name { r2Dict[k] = ["name": name] }
            }
            envConfigDict["r2_buckets"] = r2Dict
        }
        if let ai = aiBindings {
            var aiDict: [String: Any] = [:]
            for (k, v) in ai {
                aiDict[k] = ["project_id": v.projectId ?? ""]
            }
            envConfigDict["ai_bindings"] = aiDict
        }
        
        let payload: [String: Any] = [
            "deployment_configs": [
                environment: envConfigDict
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/pages/projects/\(projectName)", method: "PATCH", body: data)
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
}
