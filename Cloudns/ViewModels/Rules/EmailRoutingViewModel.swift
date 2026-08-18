import Foundation
import SwiftUI
import Combine

@MainActor
class EmailRoutingViewModel: BaseLoadableViewModel {
    let zoneId: String
    private let emailService: EmailRoutingServiceProtocol
    private let zoneService: ZoneServiceProtocol
    
    @Published var settings: EmailRoutingSettings?
    @Published var rules: [EmailRoutingRule] = []
    @Published var destinations: [EmailDestinationAddress] = []
    
    init(
        zoneId: String,
        emailService: EmailRoutingServiceProtocol = EmailRoutingService.shared,
        zoneService: ZoneServiceProtocol = ZoneService.shared
    ) {
        self.zoneId = zoneId
        self.emailService = emailService
        self.zoneService = zoneService
        super.init()
    }
    
    func fetchData() async {
        await executeLoadingTask {
            let zone = try await self.zoneService.getZoneDetails(zoneId: self.zoneId)
            let accountId = zone.account?.id ?? ""
            
            async let fetchSettings = self.emailService.getEmailRoutingSettings(zoneId: self.zoneId)
            async let fetchRules = self.emailService.getEmailRoutingRules(zoneId: self.zoneId)
            async let fetchDests = self.emailService.getEmailDestinations(accountId: accountId)
            
            let (newSettings, newRules, newDests) = try await (fetchSettings, fetchRules, fetchDests)
            self.settings = newSettings
            self.rules = newRules
            self.destinations = newDests
        }
    }
    
    func createForwardRule(name: String, customAddress: String, destinationAddress: String) async {
        let ruleInput = EmailRoutingRuleInput.forward(name: name, to: customAddress, destination: destinationAddress, enabled: true)
        
        do {
            _ = try await emailService.createEmailRoutingRule(zoneId: zoneId, rule: ruleInput)
            HapticManager.notification(.success)
            await fetchData()
        } catch {
            self.errorMessage = "Failed to create rule: \(error.localizedDescription)"
            HapticManager.notification(.error)
        }
    }
    
    func deleteRule(ruleId: String) async {
        do {
            try await emailService.deleteEmailRoutingRule(zoneId: zoneId, ruleId: ruleId)
            rules.removeAll { $0.id == ruleId }
            HapticManager.notification(.success)
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
