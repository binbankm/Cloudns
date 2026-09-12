import Combine
import Foundation

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

        if !hasFetchedData {
            if let cached = await SWRCacheStore.shared.get(forKey: scopedKey, as: [WAFRule].self), !cached.isEmpty {
                rules = cached
                hasFetchedData = true
            }
        }

        await executeLoadingTask {
            if let rs = try await self.wafService.fetchRulesetByPhase(zoneId: zoneId, phase: "http_request_firewall_custom") {
                self.ruleset = rs
                let latestRules = rs.rules ?? []
                self.rules = latestRules
                await SWRCacheStore.shared.set(latestRules, forKey: scopedKey)
            } else {
                self.ruleset = nil
                self.rules = []
            }
        }
    }

    func toggleRule(zoneId: String, rule: WAFRule) async {
        guard let rs = ruleset else { return }
        let scopedKey = SWRCacheStore.accountScopedKey("waf_rules_\(zoneId)")

        // Optimistic UI update
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            let updatedRule = WAFRule(id: rule.id, action: rule.action, expression: rule.expression, description: rule.description, enabled: !rule.enabled, ratelimit: rule.ratelimit, action_parameters: rule.action_parameters)
            rules[index] = updatedRule
            await SWRCacheStore.shared.set(rules, forKey: scopedKey)
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
        } catch {
            // Revert optimistic update on failure
            if let index = rules.firstIndex(where: { $0.id == rule.id }) {
                rules[index] = rule
                await SWRCacheStore.shared.set(rules, forKey: scopedKey)
            }
            errorMessage = error.localizedDescription
        }
    }

    func deleteRule(zoneId: String, ruleId: String) async {
        guard let rs = ruleset else { return }
        let scopedKey = SWRCacheStore.accountScopedKey("waf_rules_\(zoneId)")

        do {
            try await wafService.deleteWAFRule(zoneId: zoneId, rulesetId: rs.id, ruleId: ruleId)

            // Remove from UI
            if let index = rules.firstIndex(where: { $0.id == ruleId }) {
                rules.remove(at: index)
                await SWRCacheStore.shared.set(rules, forKey: scopedKey)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createRule(zoneId: String, action: String, expression: String, description: String, enabled: Bool) async {
        let scopedKey = SWRCacheStore.accountScopedKey("waf_rules_\(zoneId)")
        do {
            let updatedRuleset: Ruleset = if let rs = ruleset {
                try await wafService.createWAFRule(
                    zoneId: zoneId,
                    rulesetId: rs.id,
                    action: action,
                    expression: expression,
                    description: description,
                    enabled: enabled
                )
            } else {
                try await wafService.createRuleset(
                    zoneId: zoneId,
                    phase: "http_request_firewall_custom",
                    action: action,
                    expression: expression,
                    description: description,
                    enabled: enabled
                )
            }

            ruleset = updatedRuleset
            let newRules = updatedRuleset.rules ?? []
            rules = newRules
            await SWRCacheStore.shared.set(newRules, forKey: scopedKey)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
