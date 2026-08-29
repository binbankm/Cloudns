import Foundation

// MARK: - Subnet & CIDR Calculation Models

public struct SubnetCalculationResult: Equatable, Sendable {
    public let cidrInput: String
    public let ipAddress: String
    public let prefixLength: Int
    public let isIPv6: Bool
    public let networkAddress: String
    public let broadcastAddress: String
    public let netmask: String
    public let wildcardMask: String
    public let usableHostRange: String
    public let totalUsableHosts: String
    public let binaryMask: String
    public let ipClass: String
    
    public init(
        cidrInput: String,
        ipAddress: String,
        prefixLength: Int,
        isIPv6: Bool,
        networkAddress: String,
        broadcastAddress: String,
        netmask: String,
        wildcardMask: String,
        usableHostRange: String,
        totalUsableHosts: String,
        binaryMask: String,
        ipClass: String
    ) {
        self.cidrInput = cidrInput
        self.ipAddress = ipAddress
        self.prefixLength = prefixLength
        self.isIPv6 = isIPv6
        self.networkAddress = networkAddress
        self.broadcastAddress = broadcastAddress
        self.netmask = netmask
        self.wildcardMask = wildcardMask
        self.usableHostRange = usableHostRange
        self.totalUsableHosts = totalUsableHosts
        self.binaryMask = binaryMask
        self.ipClass = ipClass
    }
}
