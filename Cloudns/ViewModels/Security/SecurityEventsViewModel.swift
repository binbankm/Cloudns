import Foundation
import SwiftUI
import Combine

@MainActor
class SecurityEventsViewModel: BaseLoadableViewModel {
    @Published var events: [SecurityEvent] = []
    
    let apiClient = CloudflareAPIClient.shared
    
    func fetchEvents(zoneId: String) async {
        await executeLoadingTask {
            self.events = try await self.apiClient.fetchSecurityEvents(zoneId: zoneId, limit: 50)
        }
    }
}
