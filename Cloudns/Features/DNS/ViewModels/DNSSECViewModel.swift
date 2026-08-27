import Foundation
import Combine
import SwiftUI

@MainActor
final class DNSSECViewModel: BaseLoadableViewModel {
    // MARK: - Published Properties
    @Published var dnssec: DNSSEC?
    
    // MARK: - Private Properties
    private let zoneId: String
    private let dnsService: DNSServiceProtocol
    
    // MARK: - Lifecycle / Init
    init(zoneId: String, dnsService: DNSServiceProtocol = DNSService.shared) {
        self.zoneId = zoneId
        self.dnsService = dnsService
        super.init()
    }
    
    // MARK: - Public Methods
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
