import Foundation
import SwiftUI
import Combine

@MainActor
final class SecurityEventsViewModel: BaseLoadableViewModel {
    // MARK: - Published Properties
    @Published var events: [SecurityEvent] = []
    
    // MARK: - Private Properties
    private let securityService: SecuritySettingsServiceProtocol
    
    // MARK: - Lifecycle / Init
    init(securityService: SecuritySettingsServiceProtocol = SecuritySettingsService.shared) {
        self.securityService = securityService
        super.init()
    }
    
    // MARK: - Public Methods
    func fetchEvents(zoneId: String) async {
        await executeLoadingTask {
            self.events = try await self.securityService.fetchSecurityEvents(zoneId: zoneId, limit: 50)
        }
    }
}
