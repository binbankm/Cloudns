import Foundation
import SwiftUI
import Combine

@MainActor
class TransformRulesViewModel: ObservableObject {
    let zoneId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var ruleset: Ruleset?
    @Published var rules: [WAFRule] = []
    
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(zoneId: String) {
        self.zoneId = zoneId
    }
    
    func fetchTransformRules() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let rs = try await apiClient.fetchRulesetByPhase(zoneId: zoneId, phase: "http_request_transform")
            self.ruleset = rs
            self.rules = rs?.rules ?? []
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to load transform rules: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func toggleRule(rule: WAFRule) async {
        guard let rs = ruleset else { return }
        
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
            if let index = rules.firstIndex(where: { $0.id == rule.id }) {
                let updatedRule = WAFRule(id: rule.id, action: rule.action, expression: rule.expression, description: rule.description, enabled: rule.enabled, ratelimit: rule.ratelimit, action_parameters: rule.action_parameters)
                rules[index] = updatedRule
            }
            self.errorMessage = "Failed to update rule status: \(error.localizedDescription)"
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
            self.errorMessage = "Failed to delete transform rule: \(error.localizedDescription)"
        }
    }
    
    func createRewriteRule(zoneId: String, expression: String, description: String, enabled: Bool, rewritePath: String) async {
        var params = ActionParameters()
        params.uri = URIRewrite(path: RewriteTarget(value: rewritePath, expression: nil), query: nil)
        
        do {
            let updatedRuleset: Ruleset
            if let rs = ruleset {
                updatedRuleset = try await apiClient.createWAFRule(
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
                updatedRuleset = try await apiClient.createRuleset(
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
            
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        } catch {
            self.errorMessage = "Failed to create rewrite rule: \(error.localizedDescription)"
        }
    }
}
