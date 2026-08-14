import Foundation
import SwiftUI
import Combine

@MainActor
class EmailRoutingViewModel: ObservableObject {
    let zoneId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var settings: EmailRoutingSettings?
    @Published var rules: [EmailRoutingRule] = []
    @Published var destinations: [EmailDestinationAddress] = []
    
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(zoneId: String) {
        self.zoneId = zoneId
    }
    
    func fetchData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let zone = try await apiClient.getZoneDetails(zoneId: zoneId)
            let accountId = zone.account?.id ?? ""
            
            async let fetchSettings = apiClient.getEmailRoutingSettings(zoneId: zoneId)
            async let fetchRules = apiClient.getEmailRoutingRules(zoneId: zoneId)
            async let fetchDests = apiClient.getEmailDestinations(accountId: accountId)
            
            let (newSettings, newRules, newDests) = try await (fetchSettings, fetchRules, fetchDests)
            self.settings = newSettings
            self.rules = newRules
            self.destinations = newDests
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to load email routing data: \(error.localizedDescription)"
        }
        
        isLoading = false
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
    
    func deleteRule(at offsets: IndexSet) {
        for index in offsets {
            let rule = rules[index]
            Task {
                do {
                    try await apiClient.deleteEmailRoutingRule(zoneId: zoneId, ruleId: rule.id)
                    rules.removeAll { $0.id == rule.id }
                } catch {
                    self.errorMessage = "Failed to delete rule: \(error.localizedDescription)"
                }
            }
        }
    }
}
