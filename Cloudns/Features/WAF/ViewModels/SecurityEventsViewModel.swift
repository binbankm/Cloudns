import Foundation
import SwiftUI
import Combine

@MainActor
final class SecurityEventsViewModel: BaseLoadableViewModel {
    @Published var events: [SecurityEvent] = []
    
    private let securityService: SecuritySettingsServiceProtocol
    
    init(securityService: SecuritySettingsServiceProtocol = SecuritySettingsService.shared) {
        self.securityService = securityService
        super.init()
    }
    
    func fetchEvents(zoneId: String) async {
        await executeLoadingTask {
            self.events = try await self.securityService.fetchSecurityEvents(zoneId: zoneId, limit: 50)
        }
    }
}
