import Foundation
import SwiftUI
import Combine

@MainActor
class EmailRoutingViewModel: BaseLoadableViewModel {
    let zoneId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var settings: EmailRoutingSettings?
    @Published var rules: [EmailRoutingRule] = []
    @Published var destinations: [EmailDestinationAddress] = []
    
    init(zoneId: String) {
        self.zoneId = zoneId
    }
    
    func fetchData() async {
        await executeLoadingTask {
            let zone = try await self.apiClient.getZoneDetails(zoneId: self.zoneId)
            let accountId = zone.account?.id ?? ""
            
            async let fetchSettings = self.apiClient.getEmailRoutingSettings(zoneId: self.zoneId)
            async let fetchRules = self.apiClient.getEmailRoutingRules(zoneId: self.zoneId)
            async let fetchDests = self.apiClient.getEmailDestinations(accountId: accountId)
            
            let (newSettings, newRules, newDests) = try await (fetchSettings, fetchRules, fetchDests)
            self.settings = newSettings
            self.rules = newRules
            self.destinations = newDests
        }
    }
    
    func createForwardRule(name: String, customAddress: String, destinationAddress: String) async {
        let ruleInput = EmailRoutingRuleInput.forward(name: name, to: customAddress, destination: destinationAddress, enabled: true)
        
        do {
            let _ = try await apiClient.createEmailRoutingRule(zoneId: zoneId, rule: ruleInput)
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
            await fetchData()
        } catch {
            self.errorMessage = "Failed to create rule: \(error.localizedDescription)"
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.error)
        }
    }
    
    func deleteRule(ruleId: String) async {
        do {
            try await apiClient.deleteEmailRoutingRule(zoneId: zoneId, ruleId: ruleId)
            rules.removeAll { $0.id == ruleId }
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        } catch {
            self.errorMessage = "Failed to delete rule: \(error.localizedDescription)"
        }
    }
    
    func deleteRule(at offsets: IndexSet) {
        for index in offsets {
            let rule = rules[index]
            Task {
                await deleteRule(ruleId: rule.id)
            }
        }
    }
}
