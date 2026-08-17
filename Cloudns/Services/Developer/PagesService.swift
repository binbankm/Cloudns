import Foundation

/// 统一的 Cloudflare Pages 项目与部署领域服务
final class PagesService {
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
}
