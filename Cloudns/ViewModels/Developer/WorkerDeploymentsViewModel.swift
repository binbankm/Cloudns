import Foundation
import SwiftUI
import Combine

@MainActor
class WorkerDeploymentsViewModel: BaseLoadableViewModel {
    let accountId: String
    let scriptName: String
    private let workerService: WorkerServiceProtocol
    
    @Published var deployments: [WorkerDeployment] = []
    @Published var searchText: String = ""
    @Published var isRollingBack: Bool = false
    
    init(accountId: String, scriptName: String, workerService: WorkerServiceProtocol = WorkerService.shared) {
        self.accountId = accountId
        self.scriptName = scriptName
        self.workerService = workerService
        super.init()
    }
    
    var filteredDeployments: [WorkerDeployment] {
        if searchText.isEmpty { return deployments }
        return deployments.filter {
            ($0.number.map { "\($0)" } ?? "").contains(searchText) ||
            ($0.annotations?.message ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.authorEmail ?? "").localizedCaseInsensitiveContains(searchText) ||
            $0.displaySource.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func fetchDeployments() async {
        await executeLoadingTask {
            self.deployments = try await self.workerService.getWorkerDeployments(accountId: self.accountId, scriptName: self.scriptName)
        }
    }
    
    func rollback(deployment: WorkerDeployment) async -> Bool {
        isRollingBack = true
        do {
            try await workerService.rollbackWorkerDeployment(accountId: accountId, scriptName: scriptName, deploymentId: deployment.id)
            await fetchDeployments()
            isRollingBack = false
            return true
        } catch {
            isRollingBack = false
            errorMessage = error.localizedDescription
            return false
        }
    }
}
