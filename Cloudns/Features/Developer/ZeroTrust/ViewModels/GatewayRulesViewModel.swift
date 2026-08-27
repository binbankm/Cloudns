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
        return rules.filter { $0.name.localizedStandardContains(searchText) || ($0.action).localizedStandardContains(searchText) }
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
    
    func createRule(
        name: String,
        action: String = "block",
        traffic: String,
        enabled: Bool = true,
        filters: [String] = ["dns"]
    ) async throws {
        let targetId = await resolveTargetAccountId()
        guard !targetId.isEmpty else { throw APIError.cloudflareError("Active account ID not found") }
        let newRule = try await gatewayService.createGatewayRule(
            accountId: targetId,
            name: name,
            action: action,
            traffic: traffic,
            enabled: enabled,
            filters: filters
        )
        withAnimation {
            self.rules.insert(newRule, at: 0)
        }
        await fetchRules()
    }
    
    func deleteRule(id: String) async {
        do {
            let targetId = await resolveTargetAccountId()
            guard !targetId.isEmpty else { return }
            withAnimation {
                self.rules.removeAll { $0.id == id }
            }
            try await gatewayService.deleteGatewayRule(accountId: targetId, ruleId: id)
            ToastManager.shared.showSuccess("Gateway Rule Deleted")
            await fetchRules()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}
