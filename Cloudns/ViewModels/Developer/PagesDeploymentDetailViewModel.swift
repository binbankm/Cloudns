import Foundation
import SwiftUI
import Combine

@MainActor
class PagesDeploymentDetailViewModel: BaseLoadableViewModel {
    let accountId: String
    let projectName: String
    let deployment: PagesDeployment
    private let pagesService: PagesServiceProtocol
    
    @Published var logs: [PagesDeploymentLog] = []
    var isLoadingLogs: Bool { isLoading }
    
    init(
        accountId: String,
        projectName: String,
        deployment: PagesDeployment,
        pagesService: PagesServiceProtocol = PagesService.shared
    ) {
        self.accountId = accountId
        self.projectName = projectName
        self.deployment = deployment
        self.pagesService = pagesService
        super.init()
    }
    
    func fetchLogs() async {
        await executeLoadingTask {
            self.logs = try await self.pagesService.getPagesDeploymentLogs(accountId: self.accountId, projectName: self.projectName, deploymentId: self.deployment.id)
        }
    }
}
