import Foundation
import SwiftUI
import Combine

@MainActor
final class SecurityEventsViewModel: BaseLoadableViewModel {
    @Published var events: [SecurityEvent] = []
    
    private let eventsService: SecurityEventsServiceProtocol
    
    init(eventsService: SecurityEventsServiceProtocol = SecurityEventsService.shared) {
        self.eventsService = eventsService
        super.init()
    }
    
    func fetchEvents(zoneId: String) async {
        await executeLoadingTask {
            self.events = try await self.eventsService.fetchSecurityEvents(zoneId: zoneId, limit: 50)
        }
    }
}
