import Foundation
import SwiftUI
import Combine

@MainActor
class PagesProjectDetailViewModel: BaseLoadableViewModel {
    let accountId: String
    let project: PagesProject
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var deployments: [PagesDeployment] = []
    @Published var domains: [PagesDomain] = []
    
    init(accountId: String, project: PagesProject) {
        self.accountId = accountId
        self.project = project
        super.init()
    }
    
    func fetchProjectDetails() async {
        await executeLoadingTask {
            async let fetchDeps = self.apiClient.getPagesDeployments(accountId: self.accountId, projectName: self.project.name)
            async let fetchDoms = (try? await self.apiClient.getPagesDomains(accountId: self.accountId, projectName: self.project.name)) ?? []
            
            let (deps, doms) = await (try fetchDeps, fetchDoms)
            self.deployments = deps
            self.domains = doms
        }
    }
    
    func addDomain(name: String) async throws {
        try await apiClient.addPagesDomain(accountId: accountId, projectName: project.name, domain: name)
        await fetchProjectDetails()
    }
    
    func deleteDomain(name: String) async throws {
        try await apiClient.deletePagesDomain(accountId: accountId, projectName: project.name, domain: name)
        await fetchProjectDetails()
    }

    func rollbackDeployment(id: String) async throws {
        try await apiClient.rollbackPagesDeployment(accountId: accountId, projectName: project.name, deploymentId: id)
        await fetchProjectDetails()
    }

    func retryDeployment(id: String) async throws {
        try await apiClient.retryPagesDeployment(accountId: accountId, projectName: project.name, deploymentId: id)
        await fetchProjectDetails()
    }

    func deleteDeployment(id: String) async throws {
        try await apiClient.deletePagesDeployment(accountId: accountId, projectName: project.name, deploymentId: id)
        await fetchProjectDetails()
    }
}
