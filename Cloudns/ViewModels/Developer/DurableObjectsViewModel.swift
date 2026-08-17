import Foundation
import SwiftUI
import Combine

@MainActor
final class DurableObjectsViewModel: BaseLoadableViewModel {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var namespaces: [DurableObjectNamespace] = []
    @Published var searchText: String = ""
    
    init(accountId: String) {
        self.accountId = accountId
        super.init()
    }
    
    var filteredNamespaces: [DurableObjectNamespace] {
        if searchText.isEmpty { return namespaces }
        return namespaces.filter { $0.name.localizedCaseInsensitiveContains(searchText) || ($0.script ?? "").localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchNamespaces() async {
        await executeLoadingTask {
            self.namespaces = try await self.apiClient.listDONamespaces(accountId: self.accountId)
        }
    }
}
