import Foundation
import SwiftUI
import Combine

@MainActor
final class BulkRedirectsViewModel: BaseLoadableViewModel {
    let accountId: String
    private let bulkRedirectService: BulkRedirectServiceProtocol
    
    @Published var lists: [RedirectList] = []
    @Published var searchText: String = ""
    
    init(accountId: String, bulkRedirectService: BulkRedirectServiceProtocol = BulkRedirectService.shared) {
        self.accountId = accountId
        self.bulkRedirectService = bulkRedirectService
        super.init()
    }
    
    var filteredLists: [RedirectList] {
        if searchText.isEmpty { return lists }
        return lists.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchLists() async {
        await executeLoadingTask {
            self.lists = try await self.bulkRedirectService.listRedirectLists(accountId: self.accountId)
        }
    }
    
    func createList(name: String, description: String?) async -> Bool {
        do {
            _ = try await bulkRedirectService.createRedirectList(accountId: accountId, name: name, description: description)
            ToastManager.shared.showSuccess("List Created", message: name)
            await fetchLists()
            return true
        } catch {
            ToastManager.shared.showError("Create Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteList(id: String) async {
        do {
            try await bulkRedirectService.deleteRedirectList(accountId: accountId, listId: id)
            ToastManager.shared.showSuccess("List Deleted", message: "")
            await fetchLists()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}
