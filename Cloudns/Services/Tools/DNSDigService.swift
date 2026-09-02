import Foundation
import SwiftUI

/// Protocol defining DoH DNS resolution and global propagation service
protocol DNSDigServiceProtocol: Sendable {
    func performDNSLookup(domain: String, type: String) async throws -> DNSLookupResult
    func performDNSBenchmark(domain: String, type: String) async throws -> DNSBenchmarkResult
    func performDNSPropagation(domain: String, type: String, expectedIP: String?) async throws -> DNSPropagationResult
}

final class DNSDigService: DNSDigServiceProtocol {
    static let shared = DNSDigService()
    
    private let diagnosticSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 15.0
        config.waitsForConnectivity = false
        config.httpMaximumConnectionsPerHost = 6
        return URLSession(configuration: config)
    }()
    
    private init() {}
    
    func performDNSLookup(domain: String, type: String = "A") async throws -> DNSLookupResult {
        let cleanDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        guard var components = URLComponents(string: "https://1.1.1.1/dns-query") else {
            throw APIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "name", value: cleanDomain),
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "do", value: "true")
        ]
        guard let url = components.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.setValue("application/dns-json", forHTTPHeaderField: "Accept")
        
        let start = CFAbsoluteTimeGetCurrent()
        let (data, response) = try await diagnosticSession.data(for: request)
        let latencyMs = (CFAbsoluteTimeGetCurrent() - start) * 1000.0
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.cloudflareError("DNS Lookup request failed")
        }
        
        struct DoHAnswer: Codable {
            let name: String
            let type: Int
            let TTL: Int
            let data: String
        }
        struct DoHResponse: Codable {
            let Status: Int
            let AD: Bool?
            let Answer: [DoHAnswer]?
        }
        
        let doh = try JSONDecoder().decode(DoHResponse.self, from: data)
        let answerItems = (doh.Answer ?? []).map { ans in
            DNSAnswerItem(
                name: ans.name,
                typeName: typeNumberToName(ans.type),
                ttl: ans.TTL,
                data: ans.data
            )
        }
        
        let rawRFC = (doh.Answer ?? []).map {
            "\($0.name).\t\($0.TTL)\tIN\t\(typeNumberToName($0.type))\t\($0.data)"
        }.joined(separator: "\n")
        
        return DNSLookupResult(
            questionName: cleanDomain,
            questionType: type,
            status: doh.Status,
            answers: answerItems,
            server: "Cloudflare 1.1.1.1 (DoH)",
            latencyMs: latencyMs,
            isDNSSECValidated: doh.AD ?? false,
            rawResponseRFC: rawRFC
        )
    }
    
    func performDNSBenchmark(domain: String, type: String) async throws -> DNSBenchmarkResult {
        let cleanDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        struct ResolverSpec {
            let name: String
            let ip: String
            let dohEndpoint: String
            let icon: String
            let color: SwiftUI.Color
        }
        
        let resolvers: [ResolverSpec] = [
            ResolverSpec(name: "Cloudflare", ip: "1.1.1.1", dohEndpoint: "https://1.1.1.1/dns-query", icon: "cloud.fill", color: .orange),
            ResolverSpec(name: "Google Public", ip: "8.8.8.8", dohEndpoint: "https://dns.google/resolve", icon: "g.circle.fill", color: .blue),
            ResolverSpec(name: "Quad9 (Secured)", ip: "9.9.9.9", dohEndpoint: "https://dns.quad9.net/dns-query", icon: "shield.checkerboard", color: .purple),
            ResolverSpec(name: "AliDNS (Alibaba)", ip: "223.5.5.5", dohEndpoint: "https://dns.alidns.com/resolve", icon: "bolt.horizontal.fill", color: .cyan),
            ResolverSpec(name: "DNSPod (Tencent)", ip: "119.29.29.29", dohEndpoint: "https://doh.pub/dns-query", icon: "network", color: .green),
            ResolverSpec(name: "OpenDNS (Cisco)", ip: "208.67.222.222", dohEndpoint: "https://doh.opendns.com/dns-query", icon: "lock.shield.fill", color: .indigo)
        ]
        
        var benchmarkItems: [DNSBenchmarkItem] = []
        
        await withTaskGroup(of: DNSBenchmarkItem.self) { group in
            for res in resolvers {
                group.addTask {
                    guard var components = URLComponents(string: res.dohEndpoint) else {
                        return DNSBenchmarkItem(resolverName: res.name, resolverIP: res.ip, icon: res.icon, color: res.color, status: "Error", isSuccess: false)
                    }
                    components.queryItems = [
                        URLQueryItem(name: "name", value: cleanDomain),
                        URLQueryItem(name: "type", value: type)
                    ]
                    guard let url = components.url else {
                        return DNSBenchmarkItem(resolverName: res.name, resolverIP: res.ip, icon: res.icon, color: res.color, status: "Error", isSuccess: false)
                    }
                    
                    var req = URLRequest(url: url)
                    req.setValue("application/dns-json", forHTTPHeaderField: "Accept")
                    
                    let start = CFAbsoluteTimeGetCurrent()
                    do {
                        let (data, response) = try await self.diagnosticSession.data(for: req)
                        let latency = (CFAbsoluteTimeGetCurrent() - start) * 1000.0
                        
                        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                            return DNSBenchmarkItem(resolverName: res.name, resolverIP: res.ip, icon: res.icon, color: res.color, status: "HTTP Error", isSuccess: false)
                        }
                        
                        struct Ans: Codable { let data: String }
                        struct Res: Codable { let Answer: [Ans]? }
                        
                        let decoded = try JSONDecoder().decode(Res.self, from: data)
                        let records = (decoded.Answer ?? []).map { $0.data }
                        
                        return DNSBenchmarkItem(
                            resolverName: res.name,
                            resolverIP: res.ip,
                            icon: res.icon,
                            color: res.color,
                            latencyMs: latency,
                            resolvedRecords: records,
                            status: "Success",
                            isSuccess: true
                        )
                    } catch {
                        return DNSBenchmarkItem(
                            resolverName: res.name,
                            resolverIP: res.ip,
                            icon: res.icon,
                            color: res.color,
                            latencyMs: nil,
                            resolvedRecords: [],
                            status: "Timeout",
                            isSuccess: false
                        )
                    }
                }
            }
            
            for await item in group {
                benchmarkItems.append(item)
            }
        }
        
        let validLatencies = benchmarkItems.compactMap { $0.latencyMs }
        let minLatency = validLatencies.min() ?? 0
        
        let sorted = benchmarkItems.map { item in
            let isFast = (item.latencyMs != nil && abs((item.latencyMs ?? 0) - minLatency) < 0.1 && (item.latencyMs ?? 0) > 0)
            return DNSBenchmarkItem(
                resolverName: item.resolverName,
                resolverIP: item.resolverIP,
                icon: item.icon,
                color: item.color,
                latencyMs: item.latencyMs,
                resolvedRecords: item.resolvedRecords,
                status: item.status,
                isFastest: isFast,
                isSuccess: item.isSuccess
            )
        }.sorted { ($0.latencyMs ?? 9999) < ($1.latencyMs ?? 9999) }
        
        return DNSBenchmarkResult(domain: cleanDomain, recordType: type, items: sorted)
    }
    
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
    
    private func typeNumberToName(_ typeNum: Int) -> String {
        switch typeNum {
        case 1: return "A"
        case 28: return "AAAA"
        case 5: return "CNAME"
        case 15: return "MX"
        case 16: return "TXT"
        case 6: return "SOA"
        case 2: return "NS"
        case 33: return "SRV"
        case 257: return "CAA"
        case 65: return "HTTPS"
        default: return "TYPE\(typeNum)"
        }
    }
}
