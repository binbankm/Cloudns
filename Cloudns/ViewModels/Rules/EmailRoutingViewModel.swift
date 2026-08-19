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
    @Published var catchAllRule: EmailRoutingRule?
    @Published var accountId: String?
    
    var verifiedDestinations: [EmailDestinationAddress] {
        destinations.filter { $0.isVerified }
    }
    
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
            let accId = zone.account?.id ?? ""
            self.accountId = accId
            
            async let fetchSettings = self.emailService.getEmailRoutingSettings(zoneId: self.zoneId)
            async let fetchRules = self.emailService.getEmailRoutingRules(zoneId: self.zoneId)
            async let fetchDests = self.emailService.getEmailDestinations(accountId: accId)
            async let fetchCatchAll = (try? await self.emailService.getCatchAllRule(zoneId: self.zoneId))
            
            let (newSettings, newRules, newDests, catchAll) = try await (fetchSettings, fetchRules, fetchDests, fetchCatchAll)
            self.settings = newSettings
            self.rules = newRules
            self.destinations = newDests
            self.catchAllRule = catchAll
        }
    }
    
    func toggleEnabled(_ enabled: Bool) async {
        HapticManager.impact(.light)
        do {
            let updated: EmailRoutingSettings?
            if enabled {
                updated = try await emailService.enableEmailRouting(zoneId: zoneId)
                ToastManager.shared.showSuccess("Email Routing", message: "Enabled")
            } else {
                updated = try await emailService.disableEmailRouting(zoneId: zoneId)
                ToastManager.shared.showSuccess("Email Routing", message: "Disabled")
            }
            if let updated = updated {
                self.settings = updated
            } else {
                await fetchData()
            }
        } catch {
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Failed to Update Status", message: error.localizedDescription)
            await fetchData()
        }
    }
    
    func addDestination(email: String) async -> Bool {
        guard let accId = accountId, !accId.isEmpty else { return false }
        do {
            _ = try await emailService.createDestinationAddress(accountId: accId, email: email)
            ToastManager.shared.showSuccess("Verification Sent", message: "Check \(email) to confirm.")
            HapticManager.notification(.success)
            await fetchData()
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Failed to Add Destination", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteDestination(addressId: String) async {
        guard let accId = accountId, !accId.isEmpty else { return }
        do {
            try await emailService.deleteDestinationAddress(accountId: accId, addressId: addressId)
            destinations.removeAll { $0.id == addressId }
            ToastManager.shared.showSuccess("Destination Removed", message: "")
            HapticManager.notification(.success)
        } catch {
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
    
    func toggleCatchAll(enabled: Bool) async {
        HapticManager.impact(.light)
        do {
            let updated = try await emailService.updateCatchAllRule(zoneId: zoneId, enabled: enabled, action: "drop", forwardTo: nil)
            self.catchAllRule = updated
            ToastManager.shared.showSuccess("Catch-all Rule", message: enabled ? "Enabled" : "Disabled")
        } catch {
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Failed to update Catch-all", message: error.localizedDescription)
        }
    }
    
    func createForwardRule(name: String, customAddress: String, destinationAddress: String) async {
        let ruleInput = EmailRoutingRuleInput.forward(name: name, to: customAddress, destination: destinationAddress, enabled: true)
        
        do {
            _ = try await emailService.createEmailRoutingRule(zoneId: zoneId, rule: ruleInput)
            ToastManager.shared.showSuccess("Email Rule Added", message: "\(customAddress) -> \(destinationAddress)")
            HapticManager.notification(.success)
            await fetchData()
        } catch {
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Failed to Add Rule", message: error.localizedDescription)
            HapticManager.notification(.error)
        }
    }
    
    func deleteRule(ruleId: String) async {
        do {
            try await emailService.deleteEmailRoutingRule(zoneId: zoneId, ruleId: ruleId)
            rules.removeAll { $0.id == ruleId }
            ToastManager.shared.showSuccess("Email Rule Deleted", message: "")
            HapticManager.notification(.success)
        } catch {
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
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
