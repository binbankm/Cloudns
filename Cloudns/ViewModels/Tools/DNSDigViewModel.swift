import Foundation
import SwiftUI
import Combine

@MainActor
final class DNSDigViewModel: BaseLoadableViewModel {
    @Published var domainInput: String = ""
    @Published var selectedRecordType: String = "A"
    @Published var dnsResult: DNSLookupResult?
    @Published var benchmarkResult: DNSBenchmarkResult?
    @Published var isDnsLoading = false
    @Published var isBenchmarkLoading = false
    @Published var dnsError: String?
    @Published var showingRFCExport = false
    @Published var dnssecEnabled = false
    
    let recordTypes = ["A", "AAAA", "CNAME", "MX", "TXT", "NS", "SOA", "SRV", "CAA", "HTTPS", "PTR", "DNSKEY", "DS"]
    
    private let dnsService: DNSDigServiceProtocol
    
    init(dnsService: DNSDigServiceProtocol = DNSDigService.shared) {
        self.dnsService = dnsService
        super.init()
    }
    
    func performDNSLookup() async {
        let clean = domainInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        isDnsLoading = true
        dnsError = nil
        dnsResult = nil
        
        do {
            let res = try await dnsService.performDNSLookup(domain: clean, type: selectedRecordType)
            self.dnsResult = res
            self.hasFetchedData = true
            HapticManager.success()
        } catch {
            self.dnsError = error.localizedDescription
            HapticManager.error()
        }
        isDnsLoading = false
    }
    
    func performDNSBenchmark() async {
        let clean = domainInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        isBenchmarkLoading = true
        benchmarkResult = nil
        
        do {
            let res = try await dnsService.performDNSBenchmark(domain: clean, type: selectedRecordType)
            self.benchmarkResult = res
            self.hasFetchedData = true
            HapticManager.success()
        } catch {
            HapticManager.error()
        }
        isBenchmarkLoading = false
    }
    
    func queryDNS() async {
        await performDNSLookup()
    }
    
    func queryBenchmark() async {
        await performDNSBenchmark()
    }
    
    func runDNSBenchmark() async {
        await performDNSBenchmark()
    }
}
