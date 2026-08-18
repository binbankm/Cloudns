import Foundation
import SwiftUI
import Combine

@MainActor
class SecurityViewModel: BaseLoadableViewModel {
    @Published var securityLevel: String = "medium"
    @Published var challengeTTL: Int = 1800
    @Published var browserCheck: Bool = true
    @Published var botFightMode: Bool = false
    
    private let securityService: SecuritySettingsServiceProtocol
    
    init(securityService: SecuritySettingsServiceProtocol = SecuritySettingsService.shared) {
        self.securityService = securityService
        super.init()
    }
    
    func fetchSettings(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let res = try await securityService.getSecuritySettings(zoneId: zoneId)
            self.securityLevel = res.level
            self.challengeTTL = res.challengeTTL
            self.browserCheck = res.browserCheck
            self.botFightMode = res.botFightMode
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to fetch security settings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateSecurityLevel(zoneId: String, level: String) async {
        HapticManager.impact(.medium)
        do {
            try await securityService.updateSecurityLevel(zoneId: zoneId, level: level)
            self.securityLevel = level
        } catch {
            self.errorMessage = "Failed to update security level: \(error.localizedDescription)"
        }
    }
    
    func updateChallengeTTL(zoneId: String, ttl: Int) async {
        HapticManager.impact(.medium)
        do {
            try await securityService.updateChallengeTTL(zoneId: zoneId, ttl: ttl)
            self.challengeTTL = ttl
        } catch {
            self.errorMessage = "Failed to update challenge TTL: \(error.localizedDescription)"
        }
    }
    
    func updateBrowserCheck(zoneId: String, isOn: Bool) async {
        HapticManager.impact(.medium)
        do {
            try await securityService.updateBrowserCheck(zoneId: zoneId, isOn: isOn)
            self.browserCheck = isOn
        } catch {
            self.errorMessage = "Failed to update browser check: \(error.localizedDescription)"
        }
    }
    
    func updateBotFightMode(zoneId: String, isOn: Bool) async {
        HapticManager.impact(.medium)
        do {
            try await securityService.updateBotFightMode(zoneId: zoneId, isOn: isOn)
            self.botFightMode = isOn
        } catch {
            self.errorMessage = "Failed to update bot fight mode: \(error.localizedDescription)"
        }
    }
}
