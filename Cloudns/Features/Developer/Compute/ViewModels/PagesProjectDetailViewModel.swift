import Foundation
import SwiftUI
import Combine

@MainActor
final class PagesProjectDetailViewModel: BaseLoadableViewModel {
    // MARK: - Private Properties
    let accountId: String
    let project: PagesProject
    private let pagesService: PagesServiceProtocol
    
    // MARK: - Published Properties
    @Published var deployments: [PagesDeployment] = []
    @Published var domains: [PagesDomain] = []
    
    // MARK: - Lifecycle / Init
    init(accountId: String, project: PagesProject, pagesService: PagesServiceProtocol = PagesService.shared) {
        self.accountId = accountId
        self.project = project
        self.pagesService = pagesService
        super.init()
    }
    
    // MARK: - Public Methods
    func fetchProjectDetails() async {
        await executeLoadingTask {
            async let fetchDeps = self.pagesService.getPagesDeployments(accountId: self.accountId, projectName: self.project.name)
            async let fetchDoms = (try? await self.pagesService.getPagesDomains(accountId: self.accountId, projectName: self.project.name)) ?? []
            
            let (deps, doms) = await (try fetchDeps, fetchDoms)
            self.deployments = deps
            self.domains = doms
        }
    }
    
    func addDomain(name: String) async throws {
        try await pagesService.addPagesDomain(accountId: accountId, projectName: project.name, domain: name)
        await fetchProjectDetails()
    }
    
    func deleteDomain(name: String) async throws {
        try await pagesService.deletePagesDomain(accountId: accountId, projectName: project.name, domain: name)
        await fetchProjectDetails()
    }

    func rollbackDeployment(id: String) async throws {
        try await pagesService.rollbackPagesDeployment(accountId: accountId, projectName: project.name, deploymentId: id)
        await fetchProjectDetails()
    }

    func retryDeployment(id: String) async throws {
        try await pagesService.retryPagesDeployment(accountId: accountId, projectName: project.name, deploymentId: id)
        await fetchProjectDetails()
    }

    func deleteDeployment(id: String) async throws {
        try await pagesService.deletePagesDeployment(accountId: accountId, projectName: project.name, deploymentId: id)
        await fetchProjectDetails()
    }
}
