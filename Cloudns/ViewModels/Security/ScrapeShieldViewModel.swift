import Foundation
import SwiftUI
import Combine

@MainActor
final class ScrapeShieldViewModel: BaseLoadableViewModel {
    @Published var emailObfuscation: String = "off"
    @Published var serverSideExcludes: String = "off"
    @Published var hotlinkProtection: String = "off"
    @Published var successMessage: String?
    
    private let scrapeShieldService: ScrapeShieldServiceProtocol
    
    init(scrapeShieldService: ScrapeShieldServiceProtocol = ScrapeShieldService.shared) {
        self.scrapeShieldService = scrapeShieldService
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
    
    func fetchSettings(zoneId: String) async {
        await executeLoadingTask {
            let settings = try await self.scrapeShieldService.getScrapeShieldSettings(zoneId: zoneId)
            self.emailObfuscation = settings.emailObfuscation
            self.serverSideExcludes = settings.serverSideExcludes
            self.hotlinkProtection = settings.hotlinkProtection
        }
    }
    
    func updateSetting(zoneId: String, settingId: String, value: String) async {
        await executeLoadingTask {
            try await self.scrapeShieldService.updateScrapeShieldSetting(zoneId: zoneId, settingId: settingId, value: value)
            self.successMessage = "Setting updated successfully"
        }
    }
}
