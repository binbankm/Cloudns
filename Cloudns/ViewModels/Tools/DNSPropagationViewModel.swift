import Foundation
import SwiftUI
import Combine

@MainActor
final class DNSPropagationViewModel: BaseLoadableViewModel {
    @Published var propagationDomain = ""
    @Published var propagationType = "A"
    @Published var expectedIP = ""
    @Published var propagationResult: DNSPropagationResult?
    @Published var isPropagationLoading = false
    @Published var propagationError: String?
    
    let recordTypes = ["A", "AAAA", "CNAME", "MX", "TXT", "NS", "SOA"]
    
    private let propagationService: DNSPropagationServiceProtocol
    
    init(propagationService: DNSPropagationServiceProtocol = DNSPropagationService.shared) {
        self.propagationService = propagationService
        super.init()
    }
    
    func queryPropagation() async {
        let clean = propagationDomain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        isPropagationLoading = true
        propagationError = nil
        propagationResult = nil
        
        do {
            let res = try await propagationService.performDNSPropagation(
                domain: clean,
                type: propagationType,
                expectedIP: expectedIP.isEmpty ? nil : expectedIP
            )
            self.propagationResult = res
            self.hasFetchedData = true
            HapticManager.success()
        } catch {
            self.propagationError = error.localizedDescription
            HapticManager.error()
        }
        isPropagationLoading = false
    }
}
