import Foundation
import Combine
import SwiftUI

@MainActor
class DNSSECViewModel: ObservableObject {
    @Published var dnssec: DNSSEC?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let zoneId: String
    
    init(zoneId: String) {
        self.zoneId = zoneId
    }
    
    func fetchDNSSEC() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            self.dnssec = try await CloudflareAPIClient.shared.getDNSSEC(zoneId: zoneId)
        } catch {
            self.errorMessage = "Failed to load DNSSEC details: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func toggleDNSSEC() async {
        guard let current = dnssec else { return }
        isLoading = true
        errorMessage = nil
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        do {
            let isActiveOrPending = current.status == "active" || current.status == "pending"
            let targetStatus = isActiveOrPending ? "disabled" : "active"
            try await CloudflareAPIClient.shared.updateDNSSEC(zoneId: zoneId, status: targetStatus)
            
            // Re-fetch after update
            self.dnssec = try await CloudflareAPIClient.shared.getDNSSEC(zoneId: zoneId)
        } catch {
            self.errorMessage = "Failed to update DNSSEC status: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
