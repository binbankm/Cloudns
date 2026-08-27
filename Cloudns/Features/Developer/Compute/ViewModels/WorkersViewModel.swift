import Foundation
import SwiftUI
import Combine

@MainActor
final class WorkersViewModel: BaseLoadableViewModel {
    // MARK: - Private Properties
    let accountId: String
    private let workerService: WorkerServiceProtocol
    private let pagesService: PagesServiceProtocol
    
    // MARK: - Published Properties
    @Published var workers: [WorkerScript] = []
    @Published var pages: [PagesProject] = []
    @Published var selectedSegment = 0 // 0: Workers, 1: Pages
    @Published var searchText = ""
    
    // MARK: - Lifecycle / Init
    init(
        accountId: String,
        workerService: WorkerServiceProtocol = WorkerService.shared,
        pagesService: PagesServiceProtocol = PagesService.shared
    ) {
        self.accountId = accountId
        self.workerService = workerService
        self.pagesService = pagesService
        super.init()
    }
    
    var filteredWorkers: [WorkerScript] {
        if searchText.isEmpty { return workers }
        return workers.filter { $0.id.localizedStandardContains(searchText) }
    }
    
    var filteredPages: [PagesProject] {
        if searchText.isEmpty { return pages }
        return pages.filter { $0.name.localizedStandardContains(searchText) }
    }
    
    // MARK: - Public Methods
    func fetchData() async {
        await executeLoadingTask {
            async let fetchW = self.workerService.listWorkers(accountId: self.accountId)
            async let fetchP = self.pagesService.listPagesProjects(accountId: self.accountId)
            
            let (w, p) = try await (fetchW, fetchP)
            self.workers = w
            self.pages = p
            
            if let firstWorker = w.first {
                WidgetDataStore.shared.syncWorkerWithAnalytics(script: firstWorker, accountId: self.accountId)
            }
            if let firstPage = p.first {
                WidgetDataStore.shared.syncPagesWithAnalytics(project: firstPage, accountId: self.accountId)
            }
        }
    }
    
    func createWorker(name: String, code: String) async throws {
        try await workerService.uploadWorkerScript(accountId: accountId, scriptName: name, code: code, isModule: false)
        await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("developer_hub_overview_snapshot"))
        await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("dashboard_overview_snapshot"))
        NotificationCenter.default.post(name: .developerResourceMutated, object: nil)
        await fetchData()
    }
    
    func deleteWorker(name: String) async {
        do {
            try await workerService.deleteWorker(accountId: accountId, scriptName: name)
            await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("developer_hub_overview_snapshot"))
            await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("dashboard_overview_snapshot"))
            NotificationCenter.default.post(name: .developerResourceMutated, object: nil)
            CloudnsToastManager.shared.showSuccess("Worker Deleted", message: "\(name) removed.")
            await fetchData()
        } catch {
            CloudnsToastManager.shared.showError("Failed to delete worker", message: error.localizedDescription)
        }
    }

    func createPagesProject(name: String, branch: String) async throws {
        _ = try await pagesService.createPagesProject(accountId: accountId, name: name, productionBranch: branch)
        await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("developer_hub_overview_snapshot"))
        await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("dashboard_overview_snapshot"))
        NotificationCenter.default.post(name: .developerResourceMutated, object: nil)
        await fetchData()
    }
    
    func deletePagesProject(name: String) async {
        do {
            try await pagesService.deletePagesProject(accountId: accountId, projectName: name)
            await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("developer_hub_overview_snapshot"))
            await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("dashboard_overview_snapshot"))
            NotificationCenter.default.post(name: .developerResourceMutated, object: nil)
            CloudnsToastManager.shared.showSuccess("Pages Project Deleted", message: "\(name) removed.")
            await fetchData()
        } catch {
            CloudnsToastManager.shared.showError("Failed to delete Pages project", message: error.localizedDescription)
        }
    }
}
