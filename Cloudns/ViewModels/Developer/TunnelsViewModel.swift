import Foundation
import SwiftUI
import Combine

@MainActor
class TunnelsViewModel: BaseLoadableViewModel {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var tunnels: [CFTunnel] = []
    @Published var searchText = ""
    
    init(accountId: String) {
        self.accountId = accountId
        super.init()
    }
    
    var filteredTunnels: [CFTunnel] {
        if searchText.isEmpty { return tunnels }
        return tunnels.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchTunnels() async {
        await executeLoadingTask {
            self.tunnels = try await self.apiClient.getTunnels(accountId: self.accountId)
        }
    }
    
    func createTunnel(name: String) async -> Bool {
        do {
            let created = try await apiClient.createTunnel(accountId: accountId, name: name)
            tunnels.insert(created, at: 0)
            ToastManager.shared.showSuccess("Tunnel Created", message: name)
            return true
        } catch {
            ToastManager.shared.showError("Creation Failed", message: error.localizedDescription)
            return false
        }
    }
}
