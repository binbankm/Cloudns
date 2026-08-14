import Foundation
import SwiftUI
import Combine

@MainActor
class SecurityEventsViewModel: ObservableObject {
    @Published var events: [SecurityEvent] = []
    
    @Published var isLoading: Bool = false
    @Published var hasFetchedData: Bool = false
    @Published var errorMessage: String? = nil
    
    let apiClient = CloudflareAPIClient.shared
    
    func fetchEvents(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedEvents = try await apiClient.fetchSecurityEvents(zoneId: zoneId, limit: 50)
            self.events = fetchedEvents
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to fetch security events: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
