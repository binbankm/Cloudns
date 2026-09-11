import Foundation
import SwiftUI
import Combine

@MainActor
class RateLimitingViewModel: BaseLoadableViewModel {
    @Published var ruleset: Ruleset?
    @Published var rules: [WAFRule] = []
    
    private let wafService: WAFRulesServiceProtocol
    
    init(wafService: WAFRulesServiceProtocol = WAFRulesService.shared) {
        self.wafService = wafService
        super.init()
    }
    
    func fetchRateLimitingRules(zoneId: String) async {
        let scopedKey = SWRCacheStore.accountScopedKey("ratelimit_rules_\(zoneId)")
        
        if !hasFetchedData {
            if let cached = await SWRCacheStore.shared.get(forKey: scopedKey, as: [WAFRule].self), !cached.isEmpty {
                self.rules = cached
                self.hasFetchedData = true
            }
        }
        
        await executeLoadingTask {
            if let rs = try await self.wafService.fetchRulesetByPhase(zoneId: zoneId, phase: "http_ratelimit") {
                self.ruleset = rs
                let latest = rs.rules ?? []
                self.rules = latest
                await SWRCacheStore.shared.set(latest, forKey: scopedKey)
            } else {
                self.ruleset = nil
                self.rules = []
            }
        }
    }
    
    func toggleRule(zoneId: String, rule: WAFRule) async {
        guard let rs = ruleset else { return }
        let scopedKey = SWRCacheStore.accountScopedKey("ratelimit_rules_\(zoneId)")
        
        // Optimistic UI update
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            let updatedRule = WAFRule(id: rule.id, action: rule.action, expression: rule.expression, description: rule.description, enabled: !rule.enabled, ratelimit: rule.ratelimit, action_parameters: rule.action_parameters)
            rules[index] = updatedRule
            await SWRCacheStore.shared.set(rules, forKey: scopedKey)
        }
        
        HapticManager.notification(.success)
        
        do {
            try await wafService.updateWAFRule(
                zoneId: zoneId,
                rulesetId: rs.id,
                ruleId: rule.id,
                action: rule.action,
                expression: rule.expression,
                description: rule.description,
                enabled: !rule.enabled,
                ratelimit: rule.ratelimit
            )
        } catch {
            // Revert optimistic update on failure
            if let index = rules.firstIndex(where: { $0.id == rule.id }) {
                rules[index] = rule
                await SWRCacheStore.shared.set(rules, forKey: scopedKey)
            }
            self.errorMessage = error.localizedDescription
            HapticManager.notification(.error)
        }
    }
    
    func deleteRule(zoneId: String, ruleId: String) async {
        guard let rs = ruleset else { return }
        let scopedKey = SWRCacheStore.accountScopedKey("ratelimit_rules_\(zoneId)")
        
        do {
            try await wafService.deleteWAFRule(zoneId: zoneId, rulesetId: rs.id, ruleId: ruleId)
            
            // Remove from UI
            if let index = rules.firstIndex(where: { $0.id == ruleId }) {
                rules.remove(at: index)
                await SWRCacheStore.shared.set(rules, forKey: scopedKey)
            }
            
            HapticManager.notification(.success)
        } catch {
            self.errorMessage = error.localizedDescription
            HapticManager.notification(.error)
        }
    }
    
    func createRule(zoneId: String, action: String, expression: String, description: String, enabled: Bool, ratelimit: RateLimitConfig) async {
        let scopedKey = SWRCacheStore.accountScopedKey("ratelimit_rules_\(zoneId)")
        do {
            let updatedRuleset: Ruleset
            if let rs = ruleset {
                updatedRuleset = try await wafService.createWAFRule(
                    zoneId: zoneId,
                    rulesetId: rs.id,
                    action: action,
                    expression: expression,
                    description: description,
                    enabled: enabled,
                    ratelimit: ratelimit
                )
            } else {
                updatedRuleset = try await wafService.createRuleset(
                    zoneId: zoneId,
                    phase: "http_ratelimit",
                    action: action,
                    expression: expression,
                    description: description,
                    enabled: enabled,
                    ratelimit: ratelimit
                )
            }
            
            self.ruleset = updatedRuleset
            let newRules = updatedRuleset.rules ?? []
            self.rules = newRules
            await SWRCacheStore.shared.set(newRules, forKey: scopedKey)
            
            HapticManager.notification(.success)
        } catch {
            self.errorMessage = error.localizedDescription
            HapticManager.notification(.error)
        }
    }
}
