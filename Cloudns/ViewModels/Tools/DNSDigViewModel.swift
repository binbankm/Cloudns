import Foundation
import SwiftUI
import Combine

@MainActor
final class DNSDigViewModel: BaseLoadableViewModel {
    @Published var domain: String = ""
    @Published var selectedType: String = "A"
    @Published var lookupResult: DNSLookupResult?
    @Published var benchmarkResult: DNSBenchmarkResult?
    
    private let dnsService: DNSDigServiceProtocol
    
    init(dnsService: DNSDigServiceProtocol = DNSDigService.shared) {
        self.dnsService = dnsService
        super.init()
    }
    
    func performLookup() async {
        let clean = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        await executeLoadingTask {
            let res = try await self.dnsService.performDNSLookup(domain: clean, type: self.selectedType)
            self.lookupResult = res
            self.hasFetchedData = true
        }
    }
    
    func performBenchmark() async {
        let clean = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        await executeLoadingTask {
            let res = try await self.dnsService.performDNSBenchmark(domain: clean, type: self.selectedType)
            self.benchmarkResult = res
        }
    }
}
