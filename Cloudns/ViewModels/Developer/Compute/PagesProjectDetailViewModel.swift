import Combine
import Foundation

@MainActor
final class PagesProjectDetailViewModel: BaseLoadableViewModel {
    let accountId: String
    let project: PagesProject
    private let pagesService: PagesServiceProtocol

    @Published var deployments: [PagesDeployment] = []
    @Published var domains: [PagesDomain] = []

    var productionDeployments: [PagesDeployment] {
        deployments.filter { ($0.environment ?? "").lowercased() == "production" }
    }

    var previewDeployments: [PagesDeployment] {
        deployments.filter { ($0.environment ?? "").lowercased() != "production" }
    }

    func filteredDeployments(envFilter: String, searchText: String) -> [PagesDeployment] {
        var list = deployments
        if envFilter == "production" {
            list = productionDeployments
        } else if envFilter == "preview" {
            list = previewDeployments
        }
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return list
        }
        return list.filter { dep in
            (dep.environment ?? "").localizedStandardContains(searchText) ||
                (dep.latestStage?.status ?? "").localizedStandardContains(searchText) ||
                (dep.deploymentTrigger?.metadata?.commitMessage ?? "").localizedStandardContains(searchText) ||
                (dep.deploymentTrigger?.metadata?.branch ?? "").localizedStandardContains(searchText) ||
                (dep.deploymentTrigger?.metadata?.commitHash ?? "").localizedStandardContains(searchText) ||
                dep.id.localizedStandardContains(searchText)
        }
    }

    init(accountId: String, project: PagesProject, pagesService: PagesServiceProtocol = PagesService.shared) {
        self.accountId = accountId
        self.project = project
        self.pagesService = pagesService
        super.init()
    }

    func fetchProjectDetails() async {
        await executeLoadingTask {
            async let fetchDeps = self.pagesService.getPagesDeployments(accountId: self.accountId, projectName: self.project.name)
            async let fetchDoms = await (try? self.pagesService.getPagesDomains(accountId: self.accountId, projectName: self.project.name)) ?? []

            let (deps, doms) = try await (fetchDeps, fetchDoms)
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
