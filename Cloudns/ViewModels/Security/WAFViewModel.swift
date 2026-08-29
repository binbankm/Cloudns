import Foundation
import SwiftUI
import Combine

@MainActor
class WAFViewModel: BaseLoadableViewModel {
    @Published var ruleset: Ruleset?
    @Published var rules: [WAFRule] = []
    
    private let wafService: WAFRulesServiceProtocol
    
    init(wafService: WAFRulesServiceProtocol = WAFRulesService.shared) {
        self.wafService = wafService
        super.init()
    }
    
    func fetchWAFRules(zoneId: String) async {
        let scopedKey = SWRCacheStore.accountScopedKey("waf_rules_\(zoneId)")
        
        // 1. [SWR Stale Cache] 优先从本地缓存秒级直出
        if !hasFetchedData {
            if let cached = await SWRCacheStore.shared.get(forKey: scopedKey, as: [WAFRule].self), !cached.isEmpty {
                self.rules = cached
                self.hasFetchedData = true
            }
        }
        
        await executeLoadingTask {
            if let rs = try await self.wafService.fetchRulesetByPhase(zoneId: zoneId, phase: "http_request_firewall_custom") {
                self.ruleset = rs
                let latestRules = rs.rules ?? []
                self.rules = latestRules
                // 2. [SWR Update Cache] 存入最新数据
                await SWRCacheStore.shared.set(latestRules, forKey: scopedKey)
            } else {
                self.ruleset = nil
                self.rules = []
            }
        }
    }
    
    func toggleRule(zoneId: String, rule: WAFRule) async {
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
                ratelimit: rule.ratelimit
            )
            HapticManager.notification(.success)
        } catch {
            // Revert optimistic update on failure
            if let index = rules.firstIndex(where: { $0.id == rule.id }) {
                rules[index] = rule
            }
            self.errorMessage = error.localizedDescription
            HapticManager.notification(.error)
        }
    }
    
    func deleteRule(zoneId: String, ruleId: String) async {
        guard let rs = ruleset else { return }
        
        do {
            try await wafService.deleteWAFRule(zoneId: zoneId, rulesetId: rs.id, ruleId: ruleId)
            
            // Remove from UI
            if let index = rules.firstIndex(where: { $0.id == ruleId }) {
                rules.remove(at: index)
            }
            
            HapticManager.notification(.success)
        } catch {
            self.errorMessage = error.localizedDescription
            HapticManager.notification(.error)
        }
    }
    
    func createRule(zoneId: String, action: String, expression: String, description: String, enabled: Bool) async {
        do {
            let updatedRuleset: Ruleset
            if let rs = ruleset {
                updatedRuleset = try await wafService.createWAFRule(
                    zoneId: zoneId,
                    rulesetId: rs.id,
                    action: action,
                    expression: expression,
                    description: description,
                    enabled: enabled
                )
            } else {
                updatedRuleset = try await wafService.createRuleset(
                    zoneId: zoneId,
                    phase: "http_request_firewall_custom",
                    action: action,
                    expression: expression,
                    description: description,
                    enabled: enabled
                )
            }
            
            self.ruleset = updatedRuleset
            self.rules = updatedRuleset.rules ?? []
            
            HapticManager.notification(.success)
        } catch {
            self.errorMessage = error.localizedDescription
            HapticManager.notification(.error)
        }
    }
}
