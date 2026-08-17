import Foundation
import SwiftUI
import Combine

@MainActor
class PagesDeploymentDetailViewModel: BaseLoadableViewModel {
    let accountId: String
    let projectName: String
    let deployment: PagesDeployment
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var logs: [PagesDeploymentLog] = []
    var isLoadingLogs: Bool { isLoading }
    
    init(accountId: String, projectName: String, deployment: PagesDeployment) {
        self.accountId = accountId
        self.projectName = projectName
        self.deployment = deployment
        super.init()
    }
    
    func fetchLogs() async {
        await executeLoadingTask {
            self.logs = try await self.apiClient.getPagesDeploymentLogs(accountId: self.accountId, projectName: self.projectName, deploymentId: self.deployment.id)
        }
    }
}
