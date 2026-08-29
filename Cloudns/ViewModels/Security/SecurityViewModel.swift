import Foundation
import SwiftUI
import Combine

@MainActor
final class SecurityViewModel: BaseLoadableViewModel {
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
        await executeLoadingTask {
            let res = try await self.securityService.getSecuritySettings(zoneId: zoneId)
            self.securityLevel = res.level
            self.challengeTTL = res.challengeTTL
            self.browserCheck = res.browserCheck
            self.botFightMode = res.botFightMode
            self.hasFetchedData = true
        }
    }
    
    func updateSecurityLevel(zoneId: String, level: String) async {
        let previous = self.securityLevel
        self.securityLevel = level
        HapticManager.impact(.medium)
        do {
            try await securityService.updateSecurityLevel(zoneId: zoneId, level: level)
            await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("zone_details_\(zoneId)"))
            NotificationCenter.default.post(name: .zoneUpdated, object: nil, userInfo: ["zoneId": zoneId])
        } catch {
            self.securityLevel = previous
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateChallengeTTL(zoneId: String, ttl: Int) async {
        let previous = self.challengeTTL
        self.challengeTTL = ttl
        HapticManager.impact(.medium)
        do {
            try await securityService.updateChallengeTTL(zoneId: zoneId, ttl: ttl)
        } catch {
            self.challengeTTL = previous
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateBrowserCheck(zoneId: String, isOn: Bool) async {
        let previous = self.browserCheck
        self.browserCheck = isOn
        HapticManager.impact(.medium)
        do {
            try await securityService.updateBrowserCheck(zoneId: zoneId, isOn: isOn)
        } catch {
            self.browserCheck = previous
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateBotFightMode(zoneId: String, isOn: Bool) async {
        let previous = self.botFightMode
        self.botFightMode = isOn
        HapticManager.impact(.medium)
        do {
            try await securityService.updateBotFightMode(zoneId: zoneId, isOn: isOn)
        } catch {
            self.botFightMode = previous
            self.errorMessage = error.localizedDescription
        }
    }
}
