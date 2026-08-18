import Foundation
import Combine
import SwiftUI

@MainActor
class DNSSECViewModel: BaseLoadableViewModel {
    @Published var dnssec: DNSSEC?
    
    private let zoneId: String
    private let dnsService: DNSServiceProtocol
    
    init(zoneId: String, dnsService: DNSServiceProtocol = DNSService.shared) {
        self.zoneId = zoneId
        self.dnsService = dnsService
        super.init()
    }
    
    func fetchDNSSEC() async {
        guard !isLoading else { return }
        await executeLoadingTask {
            self.dnssec = try await self.dnsService.getDNSSEC(zoneId: self.zoneId)
        }
    }
    
    func toggleDNSSEC() async {
        guard let current = dnssec else { return }
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        await executeLoadingTask {
            let isActiveOrPending = current.status == "active" || current.status == "pending"
            let targetStatus = isActiveOrPending ? "disabled" : "active"
            _ = try await self.dnsService.updateDNSSEC(zoneId: self.zoneId, status: targetStatus)
            
            // Re-fetch after update
            self.dnssec = try await self.dnsService.getDNSSEC(zoneId: self.zoneId)
        }
    }
}
