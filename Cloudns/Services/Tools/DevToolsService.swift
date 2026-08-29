import Foundation

/// 开发者网络诊断与安全分析领域服务抽象协议
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

/// 统一的开发者工具聚合领域服务
final class DevToolsService: DevToolsServiceProtocol {
    static let shared = DevToolsService()
    
    private let dnsService: DNSDigServiceProtocol
    private let edgeService: EdgeDiagnosticsServiceProtocol
    private let ipService: IPLookupServiceProtocol
    private let sslService: SSLCertInspectServiceProtocol
    private let httpService: HTTPInspectorServiceProtocol
    
    init(
        dnsService: DNSDigServiceProtocol = DNSDigService.shared,
        edgeService: EdgeDiagnosticsServiceProtocol = EdgeDiagnosticsService.shared,
        ipService: IPLookupServiceProtocol = IPLookupService.shared,
        sslService: SSLCertInspectServiceProtocol = SSLCertInspectService.shared,
        httpService: HTTPInspectorServiceProtocol = HTTPInspectorService.shared
    ) {
        self.dnsService = dnsService
        self.edgeService = edgeService
        self.ipService = ipService
        self.sslService = sslService
        self.httpService = httpService
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
        try await edgeService.performEdgeLatencyTest(host: host, rounds: rounds)
    }
    
    func getCFTrace(host: String = "www.cloudflare.com") async throws -> [HTTPHeaderItem] {
        try await edgeService.getCFTrace(host: host)
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
        try await ipService.getCloudflareIPs()
    }
    
    func calculateSubnet(cidr: String) -> SubnetCalculationResult? {
        ipService.calculateSubnet(cidr: cidr)
    }
    
    func fetchCloudflareStatus() async throws -> CFStatusSummary {
        guard let url = URL(string: "https://www.cloudflarestatus.com/api/v2/summary.json") else {
            throw APIError.invalidURL
        }
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        let (data, _) = try await session.data(from: url)
        let summary = try JSONDecoder().decode(CFStatusSummary.self, from: data)
        return summary
    }
}
