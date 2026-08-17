import Foundation
import SwiftUI
import Combine

@MainActor
final class HyperdriveViewModel: BaseLoadableViewModel {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var configs: [HyperdriveConfig] = []
    @Published var searchText: String = ""
    
    init(accountId: String) {
        self.accountId = accountId
        super.init()
    }
    
    var filteredConfigs: [HyperdriveConfig] {
        if searchText.isEmpty { return configs }
        return configs.filter { $0.name.localizedCaseInsensitiveContains(searchText) || ($0.origin?.host ?? "").localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchConfigs() async {
        await executeLoadingTask {
            self.configs = try await self.apiClient.listHyperdriveConfigs(accountId: self.accountId)
        }
    }
    
    func createConfig(payload: HyperdriveCreate) async -> Bool {
        do {
            _ = try await apiClient.createHyperdriveConfig(accountId: accountId, payload: payload)
            ToastManager.shared.showSuccess("Hyperdrive Created", message: payload.name)
            await fetchConfigs()
            return true
        } catch {
            ToastManager.shared.showError("Create Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteConfig(id: String) async {
        do {
            try await apiClient.deleteHyperdriveConfig(accountId: accountId, configId: id)
            ToastManager.shared.showSuccess("Hyperdrive Deleted", message: "")
            await fetchConfigs()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}
