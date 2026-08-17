import Foundation
import SwiftUI
import Combine

@MainActor
class WorkerDetailViewModel: BaseLoadableViewModel {
    let accountId: String
    @Published var worker: WorkerScript
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var scriptResult: WorkerScriptContentResult?
    @Published var modules: [WorkerModuleItem] = []
    @Published var selectedModule: WorkerModuleItem?
    @Published var scriptContent: String = ""
    @Published var bindings: [WorkerBinding] = []
    @Published var subdomain: WorkerSubdomain?
    @Published var schedules: [WorkerSchedule] = []
    @Published var isSubdomainUpdating = false
    @Published var isDeploying = false
    
    init(accountId: String, worker: WorkerScript) {
        self.accountId = accountId
        self.worker = worker
        super.init()
    }
    
    func selectModule(_ module: WorkerModuleItem) {
        self.selectedModule = module
    }
    
    func fetchDetails() async {
        await executeLoadingTask {
            async let fetchCode = self.apiClient.getWorkerScriptContent(accountId: self.accountId, scriptName: self.worker.id)
            async let fetchBindings = (try? await self.apiClient.getWorkerBindings(accountId: self.accountId, scriptName: self.worker.id)) ?? []
            async let fetchSub = (try? await self.apiClient.getWorkerSubdomain(accountId: self.accountId, scriptName: self.worker.id))
            async let fetchSched = (try? await self.apiClient.getWorkerSchedules(accountId: self.accountId, scriptName: self.worker.id)) ?? []
            async let fetchWorkers = (try? await self.apiClient.getWorkers(accountId: self.accountId)) ?? []
            
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
            try await apiClient.setWorkerSubdomain(accountId: accountId, scriptName: worker.id, enabled: enabled)
            self.subdomain = try? await apiClient.getWorkerSubdomain(accountId: accountId, scriptName: worker.id)
            ToastManager.shared.showSuccess("Subdomain Updated", message: enabled ? "workers.dev enabled" : "workers.dev disabled")
        } catch {
            ToastManager.shared.showError("Failed to update subdomain", message: error.localizedDescription)
        }
        isSubdomainUpdating = false
    }

    func deployScript(code: String, isModule: Bool) async throws {
        isDeploying = true
        defer { isDeploying = false }
        try await apiClient.createWorkerScript(accountId: accountId, name: worker.id, code: code, isModule: isModule)
        await fetchDetails()
    }
}
