import Foundation
import SwiftUI
import Combine

@MainActor
final class ScrapeShieldViewModel: BaseLoadableViewModel {
    // MARK: - Published Properties
    @Published var emailObfuscation: String = "off"
    @Published var serverSideExcludes: String = "off"
    @Published var hotlinkProtection: String = "off"
    @Published var successMessage: String?
    
    // MARK: - Private Properties
    private let securityService: SecuritySettingsServiceProtocol
    
    // MARK: - Lifecycle / Init
    init(securityService: SecuritySettingsServiceProtocol = SecuritySettingsService.shared) {
        self.securityService = securityService
        super.init()
    }
    
    // MARK: - Computed Booleans
    var emailObfuscationEnabled: Bool {
        get { emailObfuscation == "on" }
        set { emailObfuscation = newValue ? "on" : "off" }
    }
    
    var serverSideExcludesEnabled: Bool {
        get { serverSideExcludes == "on" }
        set { serverSideExcludes = newValue ? "on" : "off" }
    }
    
    var hotlinkProtectionEnabled: Bool {
        get { hotlinkProtection == "on" }
        set { hotlinkProtection = newValue ? "on" : "off" }
    }
    
    // MARK: - Public Methods
    func fetchSettings(zoneId: String) async {
        await executeLoadingTask {
            let res = try await self.securityService.getScrapeShieldSettings(zoneId: zoneId)
            self.emailObfuscation = res.emailObfuscation
            self.serverSideExcludes = res.serverSideExcludes
            self.hotlinkProtection = res.hotlinkProtection
        }
    }
    
    func updateSetting(zoneId: String, settingId: String, value: String) async {
        do {
            try await securityService.updateScrapeShieldSetting(zoneId: zoneId, settingId: settingId, value: value)
            CloudnsToastManager.shared.showSuccess("Setting Updated")
        } catch {
            self.errorMessage = "Update failed: \(error.localizedDescription)"
            CloudnsToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
}
