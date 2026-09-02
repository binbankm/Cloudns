import Foundation

/// Protocol defining developer network diagnostics and security analysis service
protocol DevToolsServiceProtocol: Sendable {
    func performDNSLookup(domain: String, type: String) async throws -> DNSLookupResult
    func performDNSBenchmark(domain: String, type: String) async throws -> DNSBenchmarkResult
    func performDNSPropagation(domain: String, type: String, expectedIP: String?) async throws -> DNSPropagationResult
    func performEdgeLatencyTest(host: String, rounds: Int) async throws -> EdgeLatencyResult
    func inspectHTTPHeaders(urlString: String, method: String) async throws -> HTTPInspectionResult
    func inspectSSLCertificate(domain: String) async throws -> SSLCertDetails
    func lookupIP(target: String) async throws -> IPLookupResult
    func getCloudflareIPs() async throws -> ([String], [String])
    func getCFTrace(host: String) async throws -> [HTTPHeaderItem]
    func fetchCloudflareStatus() async throws -> CFStatusSummary
    func calculateSubnet(cidr: String) -> SubnetCalculationResult?
}

extension DevToolsServiceProtocol {
    func performDNSLookup(domain: String, type: String = "A") async throws -> DNSLookupResult {
        try await performDNSLookup(domain: domain, type: type)
    }
    
    func getCFTrace(host: String = "www.cloudflare.com") async throws -> [HTTPHeaderItem] {
        try await getCFTrace(host: host)
    }
    
    func inspectHTTPHeaders(urlString: String) async throws -> HTTPInspectionResult {
        try await inspectHTTPHeaders(urlString: urlString, method: "HEAD")
    }
}

/// Concrete aggregated service for developer network diagnostic tools
final class DevToolsService: DevToolsServiceProtocol {
    static let shared = DevToolsService()
    
    private let dnsService: DNSDigServiceProtocol
    private let traceService: CFTraceServiceProtocol
    private let latencyService: EdgeLatencyServiceProtocol
    private let ipService: IPLookupServiceProtocol
    private let sslService: CertInspectServiceProtocol
    private let httpService: HTTPHeaderInspectorServiceProtocol
    private let cidrService: CIDRCalculatorServiceProtocol
    private let ipRangesService: CFIpRangesServiceProtocol
    private let statusService: CloudflareStatusServiceProtocol
    
    init(
        dnsService: DNSDigServiceProtocol = DNSDigService.shared,
        traceService: CFTraceServiceProtocol = CFTraceService.shared,
        latencyService: EdgeLatencyServiceProtocol = EdgeLatencyService.shared,
        ipService: IPLookupServiceProtocol = IPLookupService.shared,
        sslService: CertInspectServiceProtocol = CertInspectService.shared,
        httpService: HTTPHeaderInspectorServiceProtocol = HTTPHeaderInspectorService.shared,
        cidrService: CIDRCalculatorServiceProtocol = CIDRCalculatorService.shared,
        ipRangesService: CFIpRangesServiceProtocol = CFIpRangesService.shared,
        statusService: CloudflareStatusServiceProtocol = CloudflareStatusService.shared
    ) {
        self.dnsService = dnsService
        self.traceService = traceService
        self.latencyService = latencyService
        self.ipService = ipService
        self.sslService = sslService
        self.httpService = httpService
        self.cidrService = cidrService
        self.ipRangesService = ipRangesService
        self.statusService = statusService
    }
    
    func performDNSLookup(domain: String, type: String = "A") async throws -> DNSLookupResult {
        try await dnsService.performDNSLookup(domain: domain, type: type)
    }
    
    func performDNSBenchmark(domain: String, type: String) async throws -> DNSBenchmarkResult {
        try await dnsService.performDNSBenchmark(domain: domain, type: type)
    }
    
    func performDNSPropagation(domain: String, type: String, expectedIP: String?) async throws -> DNSPropagationResult {
        try await dnsService.performDNSPropagation(domain: domain, type: type, expectedIP: expectedIP)
    }
    
    func performEdgeLatencyTest(host: String, rounds: Int = 4) async throws -> EdgeLatencyResult {
        try await latencyService.performEdgeLatencyTest(host: host, rounds: rounds)
    }
    
    func getCFTrace(host: String = "www.cloudflare.com") async throws -> [HTTPHeaderItem] {
        try await traceService.getCFTrace(host: host)
    }
    
    func inspectHTTPHeaders(urlString: String, method: String = "HEAD") async throws -> HTTPInspectionResult {
        try await httpService.inspectHTTPHeaders(urlString: urlString, method: method)
    }
    
    func inspectSSLCertificate(domain: String) async throws -> SSLCertDetails {
        try await sslService.inspectSSLCertificate(domain: domain)
    }
    
    func lookupIP(target: String) async throws -> IPLookupResult {
        try await ipService.lookupIP(target: target)
    }
    
    func getCloudflareIPs() async throws -> ([String], [String]) {
        try await ipRangesService.getCloudflareIPs()
    }
    
    func calculateSubnet(cidr: String) -> SubnetCalculationResult? {
        cidrService.calculateSubnet(cidr: cidr)
    }
    
    func fetchCloudflareStatus() async throws -> CFStatusSummary {
        try await statusService.fetchCloudflareStatus()
    }
}
