import Foundation

/// Protocol defining multi-node global DNS propagation service
protocol DNSPropagationServiceProtocol: Sendable {
    func performDNSPropagation(domain: String, type: String, expectedIP: String?) async throws -> DNSPropagationResult
}

final class DNSPropagationService: DNSPropagationServiceProtocol {
    static let shared = DNSPropagationService()
    
    private let diagnosticSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 15.0
        config.waitsForConnectivity = false
        config.httpMaximumConnectionsPerHost = 6
        return URLSession(configuration: config)
    }()
    
    private init() {}
    
    func performDNSPropagation(domain: String, type: String, expectedIP: String?) async throws -> DNSPropagationResult {
        let cleanDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        let propagationSpecs: [(region: String, city: String, flag: String, provider: String, url: String)] = [
            ("North America", "San Jose, US", "🇺🇸", "Cloudflare Anycast", "https://1.1.1.1/dns-query"),
            ("North America", "Virginia, US", "🇺🇸", "Google Public", "https://dns.google/resolve"),
            ("Europe", "Frankfurt, DE", "🇩🇪", "Quad9 Europe", "https://dns.quad9.net/dns-query"),
            ("Europe", "London, UK", "🇬🇧", "OpenDNS Global", "https://doh.opendns.com/dns-query"),
            ("Asia Pacific", "Tokyo, JP", "🇯🇵", "Cloudflare Tokyo", "https://1.1.1.1/dns-query"),
            ("Asia Pacific", "Singapore, SG", "🇸🇬", "Google Singapore", "https://dns.google/resolve"),
            ("East Asia", "Shanghai, CN", "🇨🇳", "Alibaba Cloud", "https://dns.alidns.com/resolve"),
            ("East Asia", "Shenzhen, CN", "🇨🇳", "Tencent DNSPod", "https://doh.pub/dns-query"),
            ("Oceania", "Sydney, AU", "🇦🇺", "Cloudflare Sydney", "https://1.1.1.1/dns-query"),
            ("South America", "São Paulo, BR", "🇧🇷", "Google Brazil", "https://dns.google/resolve")
        ]
        
        var nodes: [DNSPropagationNode] = []
        
        await withTaskGroup(of: DNSPropagationNode.self) { group in
            for spec in propagationSpecs {
                group.addTask {
                    guard var components = URLComponents(string: spec.url) else {
                        return DNSPropagationNode(regionName: spec.region, locationCity: spec.city, countryFlag: spec.flag, provider: spec.provider, endpointUrl: spec.url, status: .failed)
                    }
                    components.queryItems = [
                        URLQueryItem(name: "name", value: cleanDomain),
                        URLQueryItem(name: "type", value: type)
                    ]
                    guard let targetUrl = components.url else {
                        return DNSPropagationNode(regionName: spec.region, locationCity: spec.city, countryFlag: spec.flag, provider: spec.provider, endpointUrl: spec.url, status: .failed)
                    }
                    
                    var req = URLRequest(url: targetUrl)
                    req.setValue("application/dns-json", forHTTPHeaderField: "Accept")
                    
                    let start = CFAbsoluteTimeGetCurrent()
                    do {
                        let (data, response) = try await self.diagnosticSession.data(for: req)
                        let latency = (CFAbsoluteTimeGetCurrent() - start) * 1000.0
                        
                        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                            return DNSPropagationNode(regionName: spec.region, locationCity: spec.city, countryFlag: spec.flag, provider: spec.provider, endpointUrl: spec.url, status: .failed)
                        }
                        
                        struct Ans: Codable { let data: String }
                        struct Res: Codable { let Answer: [Ans]? }
                        
                        let decoded = try JSONDecoder().decode(Res.self, from: data)
                        let records = (decoded.Answer ?? []).map { $0.data }
                        
                        var nodeStatus: DNSPropagationNode.NodeStatus = .resolved
                        if let exp = expectedIP, !exp.isEmpty {
                            nodeStatus = records.contains(where: { $0.contains(exp) }) ? .resolved : .mismatch
                        } else if records.isEmpty {
                            nodeStatus = .failed
                        }
                        
                        return DNSPropagationNode(
                            regionName: spec.region,
                            locationCity: spec.city,
                            countryFlag: spec.flag,
                            provider: spec.provider,
                            endpointUrl: spec.url,
                            resolvedIPs: records,
                            latencyMs: latency,
                            status: nodeStatus
                        )
                    } catch {
                        return DNSPropagationNode(
                            regionName: spec.region,
                            locationCity: spec.city,
                            countryFlag: spec.flag,
                            provider: spec.provider,
                            endpointUrl: spec.url,
                            status: .failed
                        )
                    }
                }
            }
            
            for await node in group {
                nodes.append(node)
            }
        }
        
        return DNSPropagationResult(
            domain: cleanDomain,
            recordType: type,
            nodes: nodes.sorted { $0.regionName < $1.regionName },
            expectedIP: expectedIP
        )
    }
}
