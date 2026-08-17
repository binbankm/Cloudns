import Foundation
import SwiftUI
import Combine

@MainActor
class CacheRulesViewModel: BaseLoadableViewModel {
    let zoneId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var ruleset: Ruleset?
    @Published var rules: [WAFRule] = []
    
    init(zoneId: String) {
        self.zoneId = zoneId
    }
    
    func fetchCacheRules() async {
        await executeLoadingTask {
            let rs = try await self.apiClient.fetchRulesetByPhase(zoneId: self.zoneId, phase: "http_request_cache_settings")
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
            try await apiClient.updateWAFRule(
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
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        } catch {
            // Revert
            if let index = rules.firstIndex(where: { $0.id == rule.id }) {
                let updatedRule = WAFRule(id: rule.id, action: rule.action, expression: rule.expression, description: rule.description, enabled: rule.enabled, ratelimit: rule.ratelimit, action_parameters: rule.action_parameters)
                rules[index] = updatedRule
            }
            self.errorMessage = "Failed to update rule status: \(error.localizedDescription)"
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.error)
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
            try await apiClient.deleteWAFRule(zoneId: zoneId, rulesetId: rs.id, ruleId: ruleId)
            rules.removeAll { $0.id == ruleId }
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        } catch {
            self.errorMessage = "Failed to delete cache rule: \(error.localizedDescription)"
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.error)
        }
    }
    
    func createRule(zoneId: String, expression: String, description: String, enabled: Bool, actionParameters: ActionParameters) async {
        do {
            let updatedRuleset: Ruleset
            if let rs = ruleset {
                updatedRuleset = try await apiClient.createWAFRule(
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
                updatedRuleset = try await apiClient.createRuleset(
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
            
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        } catch {
            self.errorMessage = "Failed to create cache rule: \(error.localizedDescription)"
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.error)
        }
    }
}
