import Foundation
import SwiftUI
import Combine

@MainActor
class AIGatewaysViewModel: BaseLoadableViewModel {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var gateways: [AIGateway] = []
    @Published var searchText: String = ""
    
    init(accountId: String) {
        self.accountId = accountId
        super.init()
    }
    
    var filteredGateways: [AIGateway] {
        if searchText.isEmpty { return gateways }
        return gateways.filter { ($0.name ?? $0.id).localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchGateways() async {
        await executeLoadingTask {
            self.gateways = try await self.apiClient.getAIGateways(accountId: self.accountId)
        }
    }
    
    func createGateway(id: String) async throws {
        try await apiClient.createAIGateway(accountId: accountId, id: id)
        await fetchGateways()
    }
    
    func deleteGateway(id: String) async throws {
        try await apiClient.deleteAIGateway(accountId: accountId, id: id)
        await fetchGateways()
    }
}
