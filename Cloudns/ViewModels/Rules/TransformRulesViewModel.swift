import Foundation
import SwiftUI
import Combine

@MainActor
class TransformRulesViewModel: BaseLoadableViewModel {
    let zoneId: String
    private let wafService: WAFRulesServiceProtocol
    
    @Published var selectedPhase: String = "http_request_transform" {
        didSet {
            Task { await fetchTransformRules() }
        }
    }
    
    @Published var ruleset: Ruleset?
    @Published var rules: [WAFRule] = []
    
    init(zoneId: String, wafService: WAFRulesServiceProtocol = WAFRulesService.shared) {
        self.zoneId = zoneId
        self.wafService = wafService
        super.init()
    }
    
    func fetchTransformRules() async {
        await executeLoadingTask {
            let rs = try await self.wafService.fetchRulesetByPhase(zoneId: self.zoneId, phase: self.selectedPhase)
            self.ruleset = rs
            self.rules = rs?.rules ?? []
        }
    }
    
    func toggleRule(rule: WAFRule) async {
        guard let rs = ruleset else { return }
        
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
            HapticManager.notification(.success)
        } catch {
            if let index = rules.firstIndex(where: { $0.id == rule.id }) {
                let updatedRule = WAFRule(id: rule.id, action: rule.action, expression: rule.expression, description: rule.description, enabled: rule.enabled, ratelimit: rule.ratelimit, action_parameters: rule.action_parameters)
                rules[index] = updatedRule
            }
            self.errorMessage = "Failed to update rule status: \(error.localizedDescription)"
        }
    }
    
    func deleteRule(at offsets: IndexSet) {
        let rulesToDelete = offsets.map { rules[$0] }
        rules.remove(atOffsets: offsets)
        Task {
            for rule in rulesToDelete {
                await performDelete(ruleId: rule.id)
            }
        }
    }
    
    func deleteRule(ruleId: String) async {
        await performDelete(ruleId: ruleId)
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
        }
    }
    
    func createRewriteRule(zoneId: String, expression: String, description: String, enabled: Bool, rewritePath: String, rewriteQuery: String? = nil) async -> Bool {
        var params = ActionParameters()
        let queryTarget = rewriteQuery.flatMap { $0.isEmpty ? nil : RewriteTarget(value: $0, expression: nil) }
        params.uri = URIRewrite(path: RewriteTarget(value: rewritePath, expression: nil), query: queryTarget)
        
        do {
            let updatedRuleset: Ruleset
            if let rs = ruleset {
                updatedRuleset = try await wafService.createWAFRule(
                    zoneId: zoneId,
                    rulesetId: rs.id,
                    action: "rewrite",
                    expression: expression,
                    description: description,
                    enabled: enabled,
                    ratelimit: nil,
                    actionParameters: params
                )
            } else {
                updatedRuleset = try await wafService.createRuleset(
                    zoneId: zoneId,
                    phase: "http_request_transform",
                    action: "rewrite",
                    expression: expression,
                    description: description,
                    enabled: enabled,
                    ratelimit: nil,
                    actionParameters: params
                )
            }
            
            self.ruleset = updatedRuleset
            self.rules = updatedRuleset.rules ?? []
            
            ToastManager.shared.showSuccess("Transform Rule Created", message: description.isEmpty ? "URL Rewrite" : description)
            HapticManager.notification(.success)
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Create Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func createHeaderRule(zoneId: String, phase: String, expression: String, description: String, enabled: Bool, headerName: String, operation: String, value: String?) async -> Bool {
        var params = ActionParameters()
        let headerTransform = HeaderTransform(operation: operation, value: operation == "set" ? value : nil, expression: nil)
        params.headers = [headerName: headerTransform]
        
        let action = "rewrite"
        
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
                    ratelimit: nil,
                    actionParameters: params
                )
            } else {
                updatedRuleset = try await wafService.createRuleset(
                    zoneId: zoneId,
                    phase: phase,
                    action: action,
                    expression: expression,
                    description: description,
                    enabled: enabled,
                    ratelimit: nil,
                    actionParameters: params
                )
            }
            
            self.ruleset = updatedRuleset
            self.rules = updatedRuleset.rules ?? []
            
            ToastManager.shared.showSuccess("Header Rule Created", message: description.isEmpty ? headerName : description)
            HapticManager.notification(.success)
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Create Failed", message: error.localizedDescription)
            return false
        }
    }
}
