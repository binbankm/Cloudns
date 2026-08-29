import Foundation

// MARK: - Global DNS Propagation Models

public struct DNSPropagationNode: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let regionName: String
    public let locationCity: String
    public let countryFlag: String
    public let provider: String
    public let endpointUrl: String
    public let resolvedIPs: [String]
    public let latencyMs: Double?
    public let status: NodeStatus
    
    public enum NodeStatus: String, Sendable {
        case pending = "Pending"
        case resolved = "Matched"
        case mismatch = "Divergent"
        case failed = "Failed"
    }
    
    public init(
        regionName: String,
        locationCity: String,
        countryFlag: String,
        provider: String,
        endpointUrl: String,
        resolvedIPs: [String] = [],
        latencyMs: Double? = nil,
        status: NodeStatus = .pending
    ) {
        self.regionName = regionName
        self.locationCity = locationCity
        self.countryFlag = countryFlag
        self.provider = provider
        self.endpointUrl = endpointUrl
        self.resolvedIPs = resolvedIPs
        self.latencyMs = latencyMs
        self.status = status
    }
}

public struct DNSPropagationResult: Equatable, Sendable {
    public let domain: String
    public let recordType: String
    public let nodes: [DNSPropagationNode]
    public let expectedIP: String?
    
    public var matchedCount: Int {
        nodes.filter { $0.status == .resolved }.count
    }
    
    public var propagationPercent: Int {
        guard !nodes.isEmpty else { return 0 }
        return Int((Double(matchedCount) / Double(nodes.count)) * 100.0)
    }
    
    public init(domain: String, recordType: String, nodes: [DNSPropagationNode], expectedIP: String? = nil) {
        self.domain = domain
        self.recordType = recordType
        self.nodes = nodes
        self.expectedIP = expectedIP
    }
}
