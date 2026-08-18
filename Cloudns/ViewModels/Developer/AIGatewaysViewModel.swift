import Foundation
import SwiftUI
import Combine

@MainActor
class AIGatewaysViewModel: BaseLoadableViewModel {
    let accountId: String
    private let aiService: AIServiceProtocol
    
    @Published var gateways: [AIGateway] = []
    @Published var searchText: String = ""
    
    init(accountId: String, aiService: AIServiceProtocol = AIService.shared) {
        self.accountId = accountId
        self.aiService = aiService
        super.init()
    }
    
    var filteredGateways: [AIGateway] {
        if searchText.isEmpty { return gateways }
        return gateways.filter { ($0.name ?? $0.id).localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchGateways() async {
        await executeLoadingTask {
            self.gateways = try await self.aiService.listAIGateways(accountId: self.accountId)
        }
    }
    
    func createGateway(id: String) async throws {
        try await aiService.createAIGateway(accountId: accountId, id: id)
        await fetchGateways()
    }
    
    func deleteGateway(id: String) async throws {
        try await aiService.deleteAIGateway(accountId: accountId, id: id)
        await fetchGateways()
    }
}
