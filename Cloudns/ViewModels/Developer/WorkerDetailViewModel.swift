import Foundation
import SwiftUI
import Combine

@MainActor
class WorkerDetailViewModel: BaseLoadableViewModel {
    let accountId: String
    @Published var worker: WorkerScript
    private let workerService: WorkerServiceProtocol
    
    @Published var scriptResult: WorkerScriptContentResult?
    @Published var modules: [WorkerModuleItem] = []
    @Published var selectedModule: WorkerModuleItem?
    @Published var scriptContent: String = ""
    @Published var bindings: [WorkerBinding] = []
    @Published var subdomain: WorkerSubdomain?
    @Published var schedules: [WorkerSchedule] = []
    @Published var isSubdomainUpdating = false
    @Published var isDeploying = false
    
    init(accountId: String, worker: WorkerScript, workerService: WorkerServiceProtocol = WorkerService.shared) {
        self.accountId = accountId
        self.worker = worker
        self.workerService = workerService
        super.init()
    }
    
    func selectModule(_ module: WorkerModuleItem) {
        self.selectedModule = module
    }
    
    func fetchDetails() async {
        await executeLoadingTask {
            async let fetchCode = self.workerService.getWorkerContent(accountId: self.accountId, scriptName: self.worker.id)
            async let fetchBindings = (try? await self.workerService.getWorkerBindings(accountId: self.accountId, scriptName: self.worker.id)) ?? []
            async let fetchSub = (try? await self.workerService.getWorkerSubdomain(accountId: self.accountId, scriptName: self.worker.id))
            async let fetchSched = (try? await self.workerService.getWorkerSchedules(accountId: self.accountId, scriptName: self.worker.id)) ?? []
            async let fetchWorkers = (try? await self.workerService.listWorkers(accountId: self.accountId)) ?? []
            
            let (result, b, sub, sched, workersList) = await (try fetchCode, fetchBindings, fetchSub, fetchSched, fetchWorkers)
            self.scriptResult = result
            self.scriptContent = result.rawCode
            self.modules = result.modules
            self.selectedModule = result.modules.first(where: { $0.isMain }) ?? result.modules.first
            self.bindings = b
            self.subdomain = sub
            self.schedules = sched
            
            if let latestWorker = workersList.first(where: { $0.id == self.worker.id }) {
                self.worker = latestWorker
            }
        }
    }
    
    func toggleSubdomain(enabled: Bool) async {
        isSubdomainUpdating = true
        do {
            try await workerService.setWorkerSubdomain(accountId: accountId, scriptName: worker.id, enabled: enabled)
            self.subdomain = try? await workerService.getWorkerSubdomain(accountId: accountId, scriptName: worker.id)
            ToastManager.shared.showSuccess("Subdomain Updated", message: enabled ? "workers.dev enabled" : "workers.dev disabled")
        } catch {
            ToastManager.shared.showError("Failed to update subdomain", message: error.localizedDescription)
        }
        isSubdomainUpdating = false
    }

    func deployScript(code: String, isModule: Bool) async throws {
        isDeploying = true
        defer { isDeploying = false }
        try await workerService.uploadWorkerScript(accountId: accountId, scriptName: worker.id, code: code, isModule: isModule)
        await fetchDetails()
    }
}
