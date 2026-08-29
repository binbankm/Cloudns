import Foundation
import SwiftUI
import Combine

@MainActor
final class DNSPropagationViewModel: BaseLoadableViewModel {
    @Published var domain: String = ""
    @Published var selectedType: String = "A"
    @Published var expectedIP: String = ""
    @Published var propagationResult: DNSPropagationResult?
    
    private let propagationService: DNSPropagationServiceProtocol
    
    init(propagationService: DNSPropagationServiceProtocol = DNSPropagationService.shared) {
        self.propagationService = propagationService
        super.init()
    }
    
    func probeWorldwide() async {
        let clean = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        await executeLoadingTask {
            let res = try await self.propagationService.performDNSPropagation(
                domain: clean,
                type: self.selectedType,
                expectedIP: self.expectedIP.isEmpty ? nil : self.expectedIP
            )
            self.propagationResult = res
            self.hasFetchedData = true
        }
    }
}
