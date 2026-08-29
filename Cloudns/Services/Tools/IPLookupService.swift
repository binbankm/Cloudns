import Foundation

/// IP/ASN 归属地与子网 CIDR 计算领域服务协议
protocol IPLookupServiceProtocol: Sendable {
    func lookupIP(target: String) async throws -> IPLookupResult
    func getCloudflareIPs() async throws -> ([String], [String])
    func calculateSubnet(cidr: String) -> SubnetCalculationResult?
}

final class IPLookupService: IPLookupServiceProtocol {
    static let shared = IPLookupService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private let diagnosticSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 15.0
        config.waitsForConnectivity = false
        config.httpMaximumConnectionsPerHost = 6
        return URLSession(configuration: config)
    }()
    
    private init() {}
    
    func lookupIP(target: String) async throws -> IPLookupResult {
        let clean = target.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw APIError.invalidURL }
        
        guard let url = URL(string: "https://ipapi.co/\(clean)/json/") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await diagnosticSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.cloudflareError("IP intelligence lookup rate limited or unavailable.")
        }
        
        struct IPAPIResponse: Codable {
            let ip: String?
            let city: String?
            let region: String?
            let country_name: String?
            let country_code: String?
            let timezone: String?
            let latitude: Double?
            let longitude: Double?
            let asn: String?
            let org: String?
        }
        
        let res = try JSONDecoder().decode(IPAPIResponse.self, from: data)
        let orgName = res.org ?? ""
        let isCF = orgName.lowercased().contains("cloudflare") || (res.asn?.uppercased().contains("AS13335") ?? false)
        
        return IPLookupResult(
            query: clean,
            ip: res.ip ?? clean,
            asn: res.asn,
            org: res.org,
            country: res.country_name,
            countryCode: res.country_code,
            city: res.city,
            region: res.region,
            timezone: res.timezone,
            latitude: res.latitude,
            longitude: res.longitude,
            isCloudflareAnycast: isCF,
            cloudProvider: isCF ? "Cloudflare Anycast Global Edge" : (res.org ?? "Standard ISP/Host")
        )
    }
    
    func getCloudflareIPs() async throws -> ([String], [String]) {
        let request = try factory.createAuthenticatedRequest(path: "ips")
        struct CFIPsResponse: Codable {
            let ipv4_cidrs: [String]?
            let ipv6_cidrs: [String]?
        }
        let (data, _): (CFIPsResponse?, ResultInfo?) = try await client.performRequest(request)
        return (data?.ipv4_cidrs ?? [], data?.ipv6_cidrs ?? [])
    }
    
    func calculateSubnet(cidr: String) -> SubnetCalculationResult? {
        let clean = cidr.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = clean.split(separator: "/")
        guard parts.count == 2,
              let prefix = Int(parts[1]),
              prefix >= 0, prefix <= 32 else {
            return nil
        }
        
        let ipStr = String(parts[0])
        let octets = ipStr.split(separator: ".").compactMap { UInt32($0) }
        guard octets.count == 4, octets.allSatisfy({ $0 <= 255 }) else {
            return nil
        }
        
        let ipNum = (octets[0] << 24) | (octets[1] << 16) | (octets[2] << 8) | octets[3]
        let maskNum: UInt32 = prefix == 0 ? 0 : (0xFFFFFFFF << (32 - prefix))
        let wildNum = ~maskNum
        let networkNum = ipNum & maskNum
        let broadcastNum = networkNum | wildNum
        
        func numToIP(_ num: UInt32) -> String {
            "\((num >> 24) & 0xFF).\((num >> 16) & 0xFF).\((num >> 8) & 0xFF).\(num & 0xFF)"
        }
        
        let netmask = numToIP(maskNum)
        let wildcard = numToIP(wildNum)
        let network = numToIP(networkNum)
        let broadcast = numToIP(broadcastNum)
        
        var usableRange = "N/A"
        var usableHosts = "0"
        
        if prefix <= 30 {
            let firstUsable = numToIP(networkNum + 1)
            let lastUsable = numToIP(broadcastNum - 1)
            usableRange = "\(firstUsable) - \(lastUsable)"
            let count = (1 << (32 - prefix)) - 2
            usableHosts = "\(count)"
        } else if prefix == 31 {
            usableRange = "\(numToIP(networkNum)) - \(numToIP(broadcastNum)) (RFC 3021 Point-to-Point)"
            usableHosts = "2"
        } else if prefix == 32 {
            usableRange = "\(numToIP(networkNum)) (Single Host)"
            usableHosts = "1"
        }
        
        let binaryStr = String(maskNum, radix: 2).padding(toLength: 32, withPad: "0", startingAt: 0)
        let formattedBinary = stride(from: 0, to: 32, by: 8).map {
            let start = binaryStr.index(binaryStr.startIndex, offsetBy: $0)
            let end = binaryStr.index(start, offsetBy: 8)
            return String(binaryStr[start..<end])
        }.joined(separator: ".")
        
        var ipClass = "Class A (Unicast)"
        if octets[0] < 128 {
            ipClass = "Class A"
        } else if octets[0] < 192 {
            ipClass = "Class B"
        } else if octets[0] < 224 {
            ipClass = "Class C"
        } else if octets[0] < 240 {
            ipClass = "Class D (Multicast)"
        } else {
            ipClass = "Class E (Experimental)"
        }
        
        return SubnetCalculationResult(
            cidrInput: clean,
            ipAddress: ipStr,
            prefixLength: prefix,
            isIPv6: false,
            networkAddress: network,
            broadcastAddress: broadcast,
            netmask: netmask,
            wildcardMask: wildcard,
            usableHostRange: usableRange,
            totalUsableHosts: usableHosts,
            binaryMask: formattedBinary,
            ipClass: ipClass
        )
    }
}
