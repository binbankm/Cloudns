import Foundation
import SwiftUI
import Combine

@MainActor
class DevToolsViewModel: BaseLoadableViewModel {
    private let devToolsService: DevToolsServiceProtocol
    
    // MARK: - DNS Dig & Benchmark
    @Published var domainInput = ""
    @Published var selectedRecordType = "A"
    @Published var dnsResult: DNSLookupResult?
    @Published var benchmarkResult: DNSBenchmarkResult?
    @Published var isDnsLoading = false
    @Published var isBenchmarkLoading = false
    @Published var dnsError: String?
    @Published var showingRFCExport = false
    
    let recordTypes = ["A", "AAAA", "CNAME", "MX", "TXT", "NS", "SOA", "SRV", "CAA", "HTTPS", "PTR", "DNSKEY", "DS"]
    
    // MARK: - DNS Global Propagation
    @Published var propagationDomain = ""
    @Published var propagationType = "A"
    @Published var expectedIP = ""
    @Published var propagationResult: DNSPropagationResult?
    @Published var isPropagationLoading = false
    @Published var propagationError: String?
    
    // MARK: - HTTP & Cache Inspector
    @Published var httpUrlInput = ""
    @Published var httpMethod = "HEAD"
    @Published var httpResult: HTTPInspectionResult?
    @Published var isHttpLoading = false
    @Published var httpError: String?
    
    let httpMethods = ["HEAD", "GET", "OPTIONS"]
    
    // MARK: - Edge Latency & Jitter Tester
    @Published var latencyHostInput = ""
    @Published var latencyResult: EdgeLatencyResult?
    @Published var isLatencyLoading = false
    @Published var latencyRounds = 6
    @Published var latencyError: String?
    
    // MARK: - Subnet & CIDR Calculator
    @Published var cidrInput = "192.168.1.0/24"
    @Published var subnetResult: SubnetCalculationResult?
    @Published var subnetError: String?
    
    init(devToolsService: DevToolsServiceProtocol = DevToolsService.shared) {
        self.devToolsService = devToolsService
        super.init()
        calculateSubnet()
    }
    
    // MARK: - DNS Dig
    func queryDNS() async {
        let target = domainInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }
        
        isDnsLoading = true
        dnsError = nil
        dnsResult = nil
        
        do {
            let result = try await devToolsService.performDNSLookup(domain: target, type: selectedRecordType)
            self.dnsResult = result
        } catch {
            self.dnsError = error.localizedDescription
        }
        
        isDnsLoading = false
    }
    
    func runDNSBenchmark() async {
        let target = domainInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }
        
        isBenchmarkLoading = true
        dnsError = nil
        
        do {
            let result = try await devToolsService.performDNSBenchmark(domain: target, type: selectedRecordType)
            self.benchmarkResult = result
        } catch {
            self.dnsError = error.localizedDescription
        }
        
        isBenchmarkLoading = false
    }
    
    // MARK: - Global Propagation
    func queryPropagation() async {
        let target = propagationDomain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }
        
        isPropagationLoading = true
        propagationError = nil
        
        do {
            let result = try await devToolsService.performDNSPropagation(
                domain: target,
                type: propagationType,
                expectedIP: expectedIP.isEmpty ? nil : expectedIP.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            self.propagationResult = result
        } catch {
            self.propagationError = error.localizedDescription
        }
        
        isPropagationLoading = false
    }
    
    // MARK: - HTTP Inspector
    func inspectHTTP() async {
        let target = httpUrlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }
        
        isHttpLoading = true
        httpError = nil
        httpResult = nil
        
        do {
            let result = try await devToolsService.inspectHTTPHeaders(urlString: target, method: httpMethod)
            self.httpResult = result
        } catch {
            self.httpError = error.localizedDescription
        }
        
        isHttpLoading = false
    }
    
    // MARK: - Edge Latency
    func testLatency() async {
        let target = latencyHostInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }
        
        isLatencyLoading = true
        latencyError = nil
        latencyResult = nil
        
        do {
            let result = try await devToolsService.performEdgeLatencyTest(host: target, rounds: latencyRounds)
            self.latencyResult = result
        } catch {
            self.latencyError = error.localizedDescription
        }
        
        isLatencyLoading = false
    }
    
    // MARK: - Subnet Calculator
    func calculateSubnet() {
        let target = cidrInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else {
            subnetResult = nil
            subnetError = nil
            return
        }
        
        if let res = devToolsService.calculateSubnet(cidr: target) {
            self.subnetResult = res
            self.subnetError = nil
        } else {
            self.subnetResult = nil
            self.subnetError = String(localized: "Invalid CIDR notation. Example: 192.168.1.0/24 or 10.0.0.0/8")
        }
    }
}
