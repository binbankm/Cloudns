import Foundation
import SwiftUI
import Combine

@MainActor
class RateLimitingViewModel: ObservableObject {
    @Published var ruleset: Ruleset?
    @Published var rules: [WAFRule] = []
    
    @Published var isLoading: Bool = false
    @Published var hasFetchedData: Bool = false
    @Published var errorMessage: String? = nil
    
    let apiClient = CloudflareAPIClient.shared
    
    func fetchRateLimitingRules(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let rs = try await apiClient.fetchRulesetByPhase(zoneId: zoneId, phase: "http_ratelimit") {
                self.ruleset = rs
                self.rules = rs.rules ?? []
            }
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to fetch rate limiting rules: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func toggleRule(zoneId: String, rule: WAFRule) async {
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
                ratelimit: rule.ratelimit
            )
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        } catch {
            // Revert optimistic update on failure
            if let index = rules.firstIndex(where: { $0.id == rule.id }) {
                rules[index] = rule
            }
            self.errorMessage = "Failed to update rate limiting rule: \(error.localizedDescription)"
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.error)
        }
    }
    
    func deleteRule(zoneId: String, ruleId: String) async {
        guard let rs = ruleset else { return }
        
        do {
            try await apiClient.deleteWAFRule(zoneId: zoneId, rulesetId: rs.id, ruleId: ruleId)
            
            // Remove from UI
            if let index = rules.firstIndex(where: { $0.id == ruleId }) {
                rules.remove(at: index)
            }
            
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        } catch {
            self.errorMessage = "Failed to delete rate limiting rule: \(error.localizedDescription)"
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.error)
        }
    }
    
    func createRule(zoneId: String, action: String, expression: String, description: String, enabled: Bool, ratelimit: RateLimitConfig) async {
        do {
            let updatedRuleset: Ruleset
            if let rs = ruleset {
                updatedRuleset = try await apiClient.createWAFRule(
                    zoneId: zoneId,
                    rulesetId: rs.id,
                    action: action,
                    expression: expression,
                    description: description,
                    enabled: enabled,
                    ratelimit: ratelimit
                )
            } else {
                updatedRuleset = try await apiClient.createRuleset(
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
            self.rules = updatedRuleset.rules ?? []
            
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        } catch {
            self.errorMessage = "Failed to create rate limiting rule: \(error.localizedDescription)"
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.error)
        }
    }
}
