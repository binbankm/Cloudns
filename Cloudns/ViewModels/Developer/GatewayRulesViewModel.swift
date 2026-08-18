import Foundation
import SwiftUI
import Combine

@MainActor
final class GatewayRulesViewModel: BaseLoadableViewModel {
    let accountId: String
    private let gatewayService: GatewayServiceProtocol
    private let zoneService: ZoneServiceProtocol
    
    @Published var rules: [GatewayRule] = []
    @Published var searchText: String = ""
    
    init(
        accountId: String,
        gatewayService: GatewayServiceProtocol = GatewayService.shared,
        zoneService: ZoneServiceProtocol = ZoneService.shared
    ) {
        self.accountId = accountId
        self.gatewayService = gatewayService
        self.zoneService = zoneService
        super.init()
    }
    
    var filteredRules: [GatewayRule] {
        if searchText.isEmpty { return rules }
        return rules.filter { $0.name.localizedCaseInsensitiveContains(searchText) || ($0.action).localizedCaseInsensitiveContains(searchText) }
    }
    
    private func resolveTargetAccountId() async -> String {
        if !accountId.isEmpty { return accountId }
        let accounts = try? await zoneService.getAccounts()
        let activeEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
        return accounts?.first(where: { $0.name == activeEmail || $0.id == activeEmail })?.id ?? accounts?.first?.id ?? ""
    }
    
    func fetchRules() async {
        await executeLoadingTask {
            let targetId = await self.resolveTargetAccountId()
            guard !targetId.isEmpty else {
                self.rules = []
                return
            }
            self.rules = try await self.gatewayService.listGatewayRules(accountId: targetId)
        }
    }
    
    func deleteRule(id: String) async {
        do {
            let targetId = await resolveTargetAccountId()
            guard !targetId.isEmpty else { return }
            try await gatewayService.deleteGatewayRule(accountId: targetId, ruleId: id)
            ToastManager.shared.showSuccess("Gateway Rule Deleted", message: "")
            await fetchRules()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}
