import Foundation
import SwiftUI
import Combine

@MainActor
final class AccessAppsViewModel: BaseLoadableViewModel {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var apps: [AccessApp] = []
    @Published var searchText: String = ""
    
    init(accountId: String) {
        self.accountId = accountId
        super.init()
    }
    
    var filteredApps: [AccessApp] {
        if searchText.isEmpty { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.domain.localizedCaseInsensitiveContains(searchText) }
    }
    
    private func resolveTargetAccountId() async -> String {
        if !accountId.isEmpty { return accountId }
        let accounts = try? await apiClient.getAccounts()
        let activeEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
        return accounts?.first(where: { $0.name == activeEmail || $0.id == activeEmail })?.id ?? accounts?.first?.id ?? ""
    }
    
    func fetchApps() async {
        await executeLoadingTask {
            let targetId = await self.resolveTargetAccountId()
            guard !targetId.isEmpty else {
                self.apps = []
                return
            }
            self.apps = try await self.apiClient.listAccessApps(accountId: targetId)
        }
    }
    
    func deleteApp(id: String) async {
        do {
            let targetId = await resolveTargetAccountId()
            guard !targetId.isEmpty else { return }
            try await apiClient.deleteAccessApp(accountId: targetId, appId: id)
            ToastManager.shared.showSuccess("Access App Deleted", message: "")
            await fetchApps()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}
