import Foundation
import SwiftUI

// MARK: - Network Diagnostic Models (DoH / DNS Dig, HTTP & SSL)

public struct DNSAnswerItem: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let name: String
    public let typeName: String
    public let ttl: Int
    public let data: String
    
    public init(name: String, typeName: String, ttl: Int, data: String) {
        self.name = name
        self.typeName = typeName
        self.ttl = ttl
        self.data = data
    }
    
    public static let placeholders: [DNSAnswerItem] = [
        DNSAnswerItem(name: "example.com", typeName: "A", ttl: 300, data: "93.184.216.34"),
        DNSAnswerItem(name: "example.com", typeName: "AAAA", ttl: 300, data: "2606:2800:220:1:248:1893:25c8:1946")
    ]
}

public struct DNSLookupResult: Equatable, Sendable {
    public let questionName: String
    public let questionType: String
    public let status: Int
    public let answers: [DNSAnswerItem]
    public let server: String
    public let latencyMs: Double
    public let isDNSSECValidated: Bool
    public let rawResponseRFC: String
    
    public init(
        questionName: String,
        questionType: String,
        status: Int,
        answers: [DNSAnswerItem],
        server: String,
        latencyMs: Double,
        isDNSSECValidated: Bool = false,
        rawResponseRFC: String = ""
    ) {
        self.questionName = questionName
        self.questionType = questionType
        self.status = status
        self.answers = answers
        self.server = server
        self.latencyMs = latencyMs
        self.isDNSSECValidated = isDNSSECValidated
        self.rawResponseRFC = rawResponseRFC
    }
}

// MARK: - Multi-Resolver Benchmark

public struct DNSBenchmarkItem: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let resolverName: String
    public let resolverIP: String
    public let icon: String
    public let color: Color
    public let latencyMs: Double?
    public let resolvedRecords: [String]
    public let status: String
    public let isFastest: Bool
    public let isSuccess: Bool
    
    public init(
        resolverName: String,
        resolverIP: String,
        icon: String,
        color: Color,
        latencyMs: Double? = nil,
        resolvedRecords: [String] = [],
        status: String = "Pending",
        isFastest: Bool = false,
        isSuccess: Bool = true
    ) {
        self.resolverName = resolverName
        self.resolverIP = resolverIP
        self.icon = icon
        self.color = color
        self.latencyMs = latencyMs
        self.resolvedRecords = resolvedRecords
        self.status = status
        self.isFastest = isFastest
        self.isSuccess = isSuccess
    }
}

public struct DNSBenchmarkResult: Equatable, Sendable {
    public let domain: String
    public let recordType: String
    public let items: [DNSBenchmarkItem]
    
    public init(domain: String, recordType: String, items: [DNSBenchmarkItem]) {
        self.domain = domain
        self.recordType = recordType
        self.items = items
    }
}

// MARK: - Global DNS Propagation

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

// MARK: - Edge Latency & Jitter

public struct EdgeLatencyPing: Identifiable, Equatable, Sendable {
    public let id: Int
    public let latencyMs: Double
    public let httpStatus: Int
    public let isSuccess: Bool
    
    public init(id: Int, latencyMs: Double, httpStatus: Int, isSuccess: Bool) {
        self.id = id
        self.latencyMs = latencyMs
        self.httpStatus = httpStatus
        self.isSuccess = isSuccess
    }
}

public struct EdgeLatencyResult: Equatable, Sendable {
    public let host: String
    public let pings: [EdgeLatencyPing]
    public let minMs: Double
    public let maxMs: Double
    public let avgMs: Double
    public let jitterMs: Double
    public let packetLossPercent: Double
    public let httpProtocol: String
    public let serverHeader: String
    public let isCloudflareEdge: Bool
    
    public init(
        host: String,
        pings: [EdgeLatencyPing],
        minMs: Double,
        maxMs: Double,
        avgMs: Double,
        jitterMs: Double,
        packetLossPercent: Double,
        httpProtocol: String = "HTTP/2",
        serverHeader: String = "cloudflare",
        isCloudflareEdge: Bool = true
    ) {
        self.host = host
        self.pings = pings
        self.minMs = minMs
        self.maxMs = maxMs
        self.avgMs = avgMs
        self.jitterMs = jitterMs
        self.packetLossPercent = packetLossPercent
        self.httpProtocol = httpProtocol
        self.serverHeader = serverHeader
        self.isCloudflareEdge = isCloudflareEdge
    }
}

// MARK: - HTTP & Cache Models

public struct HTTPHeaderItem: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let key: String
    public let value: String
    
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
    
    public static let tracePlaceholders: [HTTPHeaderItem] = [
        HTTPHeaderItem(key: "colo", value: "SFO"),
        HTTPHeaderItem(key: "ip", value: "198.51.100.42"),
        HTTPHeaderItem(key: "loc", value: "US"),
        HTTPHeaderItem(key: "warp", value: "plus"),
        HTTPHeaderItem(key: "gateway", value: "off"),
        HTTPHeaderItem(key: "kex", value: "X25519")
    ]
}

public struct HTTPInspectionResult: Equatable, Sendable {
    public let url: String
    public let statusCode: Int
    public let statusText: String
    public let headers: [HTTPHeaderItem]
    public let cfRay: String?
    public let cfCacheStatus: String?
    public let server: String?
    public let durationMs: Double
    public let ttfbMs: Double
    public let contentEncoding: String?
    public let contentType: String?
    public let httpVersion: String
    public let isHTTP3Supported: Bool
    public let responseBody: String?
    
    public var responseHeaders: [String: String] {
        headers.reduce(into: [String: String]()) { $0[$1.key] = $1.value }
    }
    
    public init(
        url: String,
        statusCode: Int,
        statusText: String,
        headers: [HTTPHeaderItem],
        cfRay: String? = nil,
        cfCacheStatus: String? = nil,
        server: String? = nil,
        durationMs: Double,
        ttfbMs: Double = 0,
        contentEncoding: String? = nil,
        contentType: String? = nil,
        httpVersion: String = "HTTP/2",
        isHTTP3Supported: Bool = false,
        responseBody: String? = nil
    ) {
        self.url = url
        self.statusCode = statusCode
        self.statusText = statusText
        self.headers = headers
        self.cfRay = cfRay
        self.cfCacheStatus = cfCacheStatus
        self.server = server
        self.durationMs = durationMs
        self.ttfbMs = ttfbMs > 0 ? ttfbMs : durationMs * 0.75
        self.contentEncoding = contentEncoding
        self.contentType = contentType
        self.httpVersion = httpVersion
        self.isHTTP3Supported = isHTTP3Supported
        self.responseBody = responseBody
    }
    
    public static let placeholder = HTTPInspectionResult(
        url: "https://example.com",
        statusCode: 200,
        statusText: "OK",
        headers: [
            HTTPHeaderItem(key: "content-type", value: "text/html; charset=UTF-8"),
            HTTPHeaderItem(key: "server", value: "cloudflare"),
            HTTPHeaderItem(key: "cf-cache-status", value: "HIT"),
            HTTPHeaderItem(key: "cf-ray", value: "89a12bc34de56789-SJC")
        ],
        cfRay: "89a12bc34de56789-SJC",
        cfCacheStatus: "HIT",
        server: "cloudflare",
        durationMs: 42.5,
        ttfbMs: 31.2,
        contentEncoding: "br",
        contentType: "text/html; charset=UTF-8",
        httpVersion: "HTTP/2",
        isHTTP3Supported: true
    )
}

// MARK: - SSL Diagnostic Models

public struct SSLCertDetails: Identifiable, Equatable, Sendable {
    public var id: String { commonName + (issuer ?? "") }
    public let commonName: String
    public let issuer: String?
    public let validityDaysRemaining: Int?
    public let protocolNegotiated: String?
    public let cipherSuite: String?
    public let chainCount: Int
    public let chainNames: [String]
    public let isCloudflareEdge: Bool
    public let validFrom: String?
    public let validUntil: String?
    public let sans: [String]
    public let signatureAlgorithm: String?
    public let keyTypeAndBits: String?
    public let isExpired: Bool
    
    public init(
        commonName: String,
        issuer: String? = nil,
        validityDaysRemaining: Int? = 90,
        protocolNegotiated: String? = "TLSv1.3",
        cipherSuite: String? = "TLS_AES_256_GCM_SHA384",
        chainCount: Int = 2,
        chainNames: [String] = [],
        isCloudflareEdge: Bool = true,
        validFrom: String? = nil,
        validUntil: String? = nil,
        sans: [String] = [],
        signatureAlgorithm: String? = "SHA-256 with RSA/ECDSA",
        keyTypeAndBits: String? = "ECDSA 256 bits (P-256)",
        isExpired: Bool = false
    ) {
        self.commonName = commonName
        self.issuer = issuer
        self.validityDaysRemaining = validityDaysRemaining
        self.protocolNegotiated = protocolNegotiated
        self.cipherSuite = cipherSuite
        self.chainCount = chainCount
        self.chainNames = chainNames.isEmpty ? [commonName, issuer ?? "Certificate Authority"] : chainNames
        self.isCloudflareEdge = isCloudflareEdge
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.sans = sans
        self.signatureAlgorithm = signatureAlgorithm
        self.keyTypeAndBits = keyTypeAndBits
        self.isExpired = isExpired
    }
    
    public static let placeholder = SSLCertDetails(
        commonName: "cloudflare.com",
        issuer: "GTS CA 1P5 (Google Trust Services)",
        validityDaysRemaining: 84,
        protocolNegotiated: "TLSv1.3",
        cipherSuite: "TLS_AES_256_GCM_SHA384",
        chainCount: 3,
        chainNames: ["cloudflare.com", "GTS CA 1P5", "GTS Root R1"],
        isCloudflareEdge: true,
        validFrom: "2024-01-01 00:00:00 UTC",
        validUntil: "2024-12-31 23:59:59 UTC",
        sans: ["cloudflare.com", "*.cloudflare.com"],
        signatureAlgorithm: "SHA-256 with ECDSA",
        keyTypeAndBits: "ECDSA 256 bits (P-256)"
    )
}

// MARK: - IP & ASN Diagnosis Models

public struct IPLookupResult: Equatable, Sendable {
    public let query: String
    public let ip: String
    public let asn: String?
    public let org: String?
    public let country: String?
    public let countryCode: String?
    public let city: String?
    public let region: String?
    public let timezone: String?
    public let latitude: Double?
    public let longitude: Double?
    public let isCloudflareAnycast: Bool
    public let cloudProvider: String?
    
    public var countryFlag: String {
        guard let code = countryCode?.uppercased(), code.count == 2 else { return "🌐" }
        return code.unicodeScalars.compactMap {
            UnicodeScalar(127397 + $0.value)
        }.map { String($0) }.joined()
    }
    
    public init(
        query: String,
        ip: String,
        asn: String? = nil,
        org: String? = nil,
        country: String? = nil,
        countryCode: String? = nil,
        city: String? = nil,
        region: String? = nil,
        timezone: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        isCloudflareAnycast: Bool = false,
        cloudProvider: String? = nil
    ) {
        self.query = query
        self.ip = ip
        self.asn = asn
        self.org = org
        self.country = country
        self.countryCode = countryCode
        self.city = city
        self.region = region
        self.timezone = timezone
        self.latitude = latitude
        self.longitude = longitude
        self.isCloudflareAnycast = isCloudflareAnycast
        self.cloudProvider = cloudProvider
    }
    
    public static let placeholder = IPLookupResult(
        query: "1.1.1.1",
        ip: "1.1.1.1",
        asn: "AS13335",
        org: "Cloudflare, Inc.",
        country: "United States",
        countryCode: "US",
        city: "San Francisco",
        region: "California",
        timezone: "America/Los_Angeles",
        latitude: 37.7749,
        longitude: -122.4194,
        isCloudflareAnycast: true,
        cloudProvider: "Cloudflare Anycast Network"
    )
}

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

// MARK: - Edge Quick Check Model

public struct EdgeQuickCheckResult: Equatable, Sendable {
    public let colo: String
    public let cityName: String
    public let countryCode: String
    public let clientIp: String
    public let rttMs: Double
    public let httpVersion: String
    public let tlsVersion: String
    public let warpActive: Bool
    public let timestamp: Date
    
    public init(
        colo: String,
        cityName: String,
        countryCode: String,
        clientIp: String,
        rttMs: Double,
        httpVersion: String,
        tlsVersion: String,
        warpActive: Bool,
        timestamp: Date = Date()
    ) {
        self.colo = colo
        self.cityName = cityName
        self.countryCode = countryCode
        self.clientIp = clientIp
        self.rttMs = rttMs
        self.httpVersion = httpVersion
        self.tlsVersion = tlsVersion
        self.warpActive = warpActive
        self.timestamp = timestamp
    }
}
