import Foundation

/// Protocol defining CIDR and subnet mask calculation service
protocol CIDRCalculatorServiceProtocol: Sendable {
    func calculateSubnet(cidr: String) -> SubnetCalculationResult?
}

final class CIDRCalculatorService: CIDRCalculatorServiceProtocol {
    static let shared = CIDRCalculatorService()
    
    private init() {}
    
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
