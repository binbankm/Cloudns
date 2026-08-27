import Foundation
import SwiftUI
import Combine

@MainActor
final class TunnelsViewModel: BaseLoadableViewModel {
    let accountId: String
    private let tunnelService: TunnelServiceProtocol
    
    @Published var tunnels: [CFTunnel] = []
    @Published var searchText = ""
    
    init(accountId: String, tunnelService: TunnelServiceProtocol = TunnelService.shared) {
        self.accountId = accountId
        self.tunnelService = tunnelService
        super.init()
    }
    
    var filteredTunnels: [CFTunnel] {
        if searchText.isEmpty { return tunnels }
        return tunnels.filter { $0.name.localizedStandardContains(searchText) }
    }
    
    func fetchTunnels() async {
        await executeLoadingTask {
            self.tunnels = try await self.tunnelService.getTunnels(accountId: self.accountId)
        }
    }
    
    func createTunnel(name: String) async -> Bool {
        do {
            let created = try await tunnelService.createTunnel(accountId: accountId, name: name)
            tunnels.insert(created, at: 0)
            await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("developer_hub_overview_snapshot"))
            await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("dashboard_overview_snapshot"))
            NotificationCenter.default.post(name: .developerResourceMutated, object: nil)
            CloudnsToastManager.shared.showSuccess("Tunnel Created", message: name)
            return true
        } catch {
            CloudnsToastManager.shared.showError("Creation Failed", message: error.localizedDescription)
            return false
        }
    }
}
