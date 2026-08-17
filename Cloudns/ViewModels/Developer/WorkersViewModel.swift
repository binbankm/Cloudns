import Foundation
import SwiftUI
import Combine

@MainActor
class WorkersViewModel: BaseLoadableViewModel {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var workers: [WorkerScript] = []
    @Published var pages: [PagesProject] = []
    @Published var selectedSegment = 0 // 0: Workers, 1: Pages
    @Published var searchText = ""
    
    init(accountId: String) {
        self.accountId = accountId
        super.init()
    }
    
    var filteredWorkers: [WorkerScript] {
        if searchText.isEmpty { return workers }
        return workers.filter { $0.id.localizedCaseInsensitiveContains(searchText) }
    }
    
    var filteredPages: [PagesProject] {
        if searchText.isEmpty { return pages }
        return pages.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchData() async {
        await executeLoadingTask {
            async let fetchW = self.apiClient.getWorkers(accountId: self.accountId)
            async let fetchP = self.apiClient.getPagesProjects(accountId: self.accountId)
            
            let (w, p) = try await (fetchW, fetchP)
            self.workers = w
            self.pages = p
        }
    }
    
    func createWorker(name: String, code: String) async throws {
        try await apiClient.createWorkerScript(accountId: accountId, name: name, code: code)
        await fetchData()
    }
    
    func deleteWorker(name: String) async throws {
        try await apiClient.deleteWorkerScript(accountId: accountId, scriptName: name)
        await fetchData()
    }

    func createPagesProject(name: String, branch: String) async throws {
        _ = try await apiClient.createPagesProject(accountId: accountId, name: name, productionBranch: branch)
        await fetchData()
    }
    
    func deletePagesProject(name: String) async throws {
        try await apiClient.deletePagesProject(accountId: accountId, projectName: name)
        await fetchData()
    }
}
