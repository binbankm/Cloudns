import Foundation
import SwiftUI
import Combine

@MainActor
class CacheRulesViewModel: BaseLoadableViewModel {
    let zoneId: String
    private let wafService: WAFRulesServiceProtocol
    
    @Published var ruleset: Ruleset?
    @Published var rules: [WAFRule] = []
    
    init(zoneId: String, wafService: WAFRulesServiceProtocol = WAFRulesService.shared) {
        self.zoneId = zoneId
        self.wafService = wafService
        super.init()
    }
    
    func fetchCacheRules() async {
        await executeLoadingTask {
            let rs = try await self.wafService.fetchRulesetByPhase(zoneId: self.zoneId, phase: "http_request_cache_settings")
            self.ruleset = rs
            self.rules = rs?.rules ?? []
        }
    }
    
    func toggleRule(rule: WAFRule) async {
        guard let rs = ruleset else { return }
        
        // Optimistic UI update
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            let updatedRule = WAFRule(id: rule.id, action: rule.action, expression: rule.expression, description: rule.description, enabled: !rule.enabled, ratelimit: rule.ratelimit, action_parameters: rule.action_parameters)
            rules[index] = updatedRule
        }
        
        do {
            try await wafService.updateWAFRule(
                zoneId: zoneId,
                rulesetId: rs.id,
                ruleId: rule.id,
                action: rule.action,
                expression: rule.expression,
                description: rule.description,
                enabled: !rule.enabled,
                ratelimit: rule.ratelimit,
                actionParameters: rule.action_parameters
            )
            ToastManager.shared.showSuccess("Cache Rule", message: !rule.enabled ? "Rule enabled" : "Rule disabled")
            HapticManager.notification(.success)
        } catch {
            // Revert
            if let index = rules.firstIndex(where: { $0.id == rule.id }) {
                let updatedRule = WAFRule(id: rule.id, action: rule.action, expression: rule.expression, description: rule.description, enabled: rule.enabled, ratelimit: rule.ratelimit, action_parameters: rule.action_parameters)
                rules[index] = updatedRule
            }
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Update Failed", message: error.localizedDescription)
            HapticManager.notification(.error)
        }
    }
    
    func deleteRule(at offsets: IndexSet) {
        for index in offsets {
            let rule = rules[index]
            Task {
                await performDelete(ruleId: rule.id)
            }
        }
    }
    
    private func performDelete(ruleId: String) async {
        guard let rs = ruleset else { return }
        
        do {
            try await wafService.deleteWAFRule(zoneId: zoneId, rulesetId: rs.id, ruleId: ruleId)
            rules.removeAll { $0.id == ruleId }
            ToastManager.shared.showSuccess("Rule Deleted", message: "")
            HapticManager.notification(.success)
        } catch {
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
            HapticManager.notification(.error)
        }
    }
    
    func createRule(zoneId: String, expression: String, description: String, enabled: Bool, actionParameters: ActionParameters) async {
        do {
            let updatedRuleset: Ruleset
            if let rs = ruleset {
                updatedRuleset = try await wafService.createWAFRule(
                    zoneId: zoneId,
                    rulesetId: rs.id,
                    action: "set_cache_settings",
                    expression: expression,
                    description: description,
                    enabled: enabled,
                    ratelimit: nil,
                    actionParameters: actionParameters
                )
            } else {
                updatedRuleset = try await wafService.createRuleset(
                    zoneId: zoneId,
                    phase: "http_request_cache_settings",
                    action: "set_cache_settings",
                    expression: expression,
                    description: description,
                    enabled: enabled,
                    ratelimit: nil,
                    actionParameters: actionParameters
                )
            }
            
            self.ruleset = updatedRuleset
            self.rules = updatedRuleset.rules ?? []
            
            ToastManager.shared.showSuccess("Cache Rule Created", message: description.isEmpty ? "Rule added" : description)
            HapticManager.notification(.success)
        } catch {
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Create Failed", message: error.localizedDescription)
            HapticManager.notification(.error)
        }
    }
}
