import Foundation
import SwiftUI
import Combine

@MainActor
final class WorkerDeploymentsViewModel: BaseLoadableViewModel {
    // MARK: - Private Properties
    let accountId: String
    let scriptName: String
    private let workerService: WorkerServiceProtocol
    
    // MARK: - Published Properties
    @Published var deployments: [WorkerDeployment] = []
    @Published var searchText: String = ""
    @Published var isRollingBack: Bool = false
    
    // MARK: - Lifecycle / Init
    init(accountId: String, scriptName: String, workerService: WorkerServiceProtocol = WorkerService.shared) {
        self.accountId = accountId
        self.scriptName = scriptName
        self.workerService = workerService
        super.init()
    }
    
    var filteredDeployments: [WorkerDeployment] {
        if searchText.isEmpty { return deployments }
        return deployments.filter {
            ($0.number.map { "\($0)" } ?? "").localizedStandardContains(searchText) ||
            ($0.annotations?.message ?? "").localizedStandardContains(searchText) ||
            ($0.authorEmail ?? "").localizedStandardContains(searchText) ||
            $0.displaySource.localizedStandardContains(searchText)
        }
    }
    
    // MARK: - Public Methods
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
