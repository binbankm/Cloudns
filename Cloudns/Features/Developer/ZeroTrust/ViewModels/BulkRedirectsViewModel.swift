import Foundation
import SwiftUI
import Combine

@MainActor
final class BulkRedirectsViewModel: BaseLoadableViewModel {
    // MARK: - Private Properties
    let accountId: String
    private let bulkRedirectService: BulkRedirectServiceProtocol
    
    // MARK: - Published Properties
    @Published var lists: [RedirectList] = []
    @Published var searchText: String = ""
    
    // MARK: - Lifecycle / Init
    init(accountId: String, bulkRedirectService: BulkRedirectServiceProtocol = BulkRedirectService.shared) {
        self.accountId = accountId
        self.bulkRedirectService = bulkRedirectService
        super.init()
    }
    
    var filteredLists: [RedirectList] {
        if searchText.isEmpty { return lists }
        return lists.filter { $0.name.localizedStandardContains(searchText) }
    }
    
    // MARK: - Public Methods
    func fetchLists() async {
        await executeLoadingTask {
            self.lists = try await self.bulkRedirectService.listRedirectLists(accountId: self.accountId)
        }
    }
    
    func createList(name: String, description: String?) async -> Bool {
        do {
            _ = try await bulkRedirectService.createRedirectList(accountId: accountId, name: name, description: description)
            CloudnsToastManager.shared.showSuccess("List Created", message: name)
            await fetchLists()
            return true
        } catch {
            CloudnsToastManager.shared.showError("Create Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteList(id: String) async {
        do {
            try await bulkRedirectService.deleteRedirectList(accountId: accountId, listId: id)
            CloudnsToastManager.shared.showSuccess("List Deleted")
            await fetchLists()
        } catch {
            CloudnsToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}
