import Foundation
import SwiftUI
import Combine

@MainActor
class RulesViewModel: ObservableObject {
    let zoneId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var rules: [PageRule] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Argo setting
    @Published var argoEnabled: Bool = false
    @Published var isArgoLoading = false
    
    init(zoneId: String) {
        self.zoneId = zoneId
    }
    
    func fetchData() async {
        isLoading = true
        errorMessage = nil
        
        async let rulesTask: () = fetchRules()
        async let argoTask: () = fetchArgoSetting()
        
        _ = await (rulesTask, argoTask)
        
        isLoading = false
    }
    
    private func fetchRules() async {
        do {
            rules = try await apiClient.getPageRules(zoneId: zoneId)
            // Sort by priority
            rules.sort { $0.priority < $1.priority }
        } catch {
            self.errorMessage = "Failed to load Page Rules: \(error.localizedDescription)"
        }
    }
    
    private func fetchArgoSetting() async {
        do {
            isArgoLoading = true
            let settings = try await apiClient.fetchZoneSettings(zoneId: zoneId)
            if let argoSetting = settings.first(where: { $0.id == "argo" }) {
                if case .string(let val) = argoSetting.value {
                    self.argoEnabled = (val == "on")
                }
            }
            isArgoLoading = false
        } catch {
            isArgoLoading = false
            // Argo might not be available for all accounts, so we silently ignore or log it
            print("Argo fetch error: \(error)")
        }
    }
    
    func toggleRuleStatus(rule: PageRule) async {
        let newStatus = rule.status == "active" ? "disabled" : "active"
        
        // Optimistic UI update
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index].status = newStatus
        }
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        do {
            try await apiClient.updatePageRuleStatus(zoneId: zoneId, ruleId: rule.id, status: newStatus)
        } catch {
            // Revert on failure
            if let index = rules.firstIndex(where: { $0.id == rule.id }) {
                rules[index].status = rule.status
            }
            self.errorMessage = "Failed to update rule status: \(error.localizedDescription)"
        }
    }
    
    func deleteRule(ruleId: String) async {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.warning)
        
        do {
            try await apiClient.deletePageRule(zoneId: zoneId, ruleId: ruleId)
            rules.removeAll { $0.id == ruleId }
        } catch {
            self.errorMessage = "Failed to delete rule: \(error.localizedDescription)"
        }
    }
    
    func toggleArgo(isOn: Bool) async {
        isArgoLoading = true
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        do {
            let value = isOn ? "on" : "off"
            try await apiClient.updateZoneSetting(zoneId: zoneId, settingId: "argo", value: .string(value))
            self.argoEnabled = isOn
            isArgoLoading = false
        } catch {
            isArgoLoading = false
            self.argoEnabled = !isOn
            self.errorMessage = "Failed to update Argo setting: \(error.localizedDescription)"
        }
    }
}
