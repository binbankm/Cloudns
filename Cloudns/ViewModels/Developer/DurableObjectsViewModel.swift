import Foundation
import SwiftUI
import Combine

@MainActor
final class DurableObjectsViewModel: BaseLoadableViewModel {
    let accountId: String
    private let doService: DurableObjectServiceProtocol
    
    @Published var namespaces: [DurableObjectNamespace] = []
    @Published var searchText: String = ""
    
    init(accountId: String, doService: DurableObjectServiceProtocol = DurableObjectService.shared) {
        self.accountId = accountId
        self.doService = doService
        super.init()
    }
    
    var filteredNamespaces: [DurableObjectNamespace] {
        if searchText.isEmpty { return namespaces }
        return namespaces.filter { $0.displayName.localizedStandardContains(searchText) || ($0.script ?? "").localizedStandardContains(searchText) }
    }
    
    func fetchNamespaces() async {
        await executeLoadingTask {
            self.namespaces = try await self.doService.listDONamespaces(accountId: self.accountId)
        }
    }
}
