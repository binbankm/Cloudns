import Foundation
import SwiftUI

// MARK: - Network Diagnostic Models (DoH / DNS Dig, HTTP & SSL)

public struct DNSAnswerItem: Identifiable, Equatable {
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

public struct DNSLookupResult: Equatable {
    public let questionName: String
    public let questionType: String
    public let status: Int
    public let answers: [DNSAnswerItem]
    public let server: String
    public let latencyMs: Double
    
    public init(questionName: String, questionType: String, status: Int, answers: [DNSAnswerItem], server: String, latencyMs: Double) {
        self.questionName = questionName
        self.questionType = questionType
        self.status = status
        self.answers = answers
        self.server = server
        self.latencyMs = latencyMs
    }
}

public struct HTTPHeaderItem: Identifiable, Equatable {
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

public struct HTTPInspectionResult: Equatable {
    public let url: String
    public let statusCode: Int
    public let statusText: String
    public let headers: [HTTPHeaderItem]
    public let cfRay: String?
    public let cfCacheStatus: String?
    public let server: String?
    public let durationMs: Double
    public let responseBody: String?
    
    public var responseHeaders: [String: String] {
        headers.reduce(into: [String: String]()) { $0[$1.key] = $1.value }
    }
    
    public init(url: String, statusCode: Int, statusText: String, headers: [HTTPHeaderItem], cfRay: String? = nil, cfCacheStatus: String? = nil, server: String? = nil, durationMs: Double, responseBody: String? = nil) {
        self.url = url
        self.statusCode = statusCode
        self.statusText = statusText
        self.headers = headers
        self.cfRay = cfRay
        self.cfCacheStatus = cfCacheStatus
        self.server = server
        self.durationMs = durationMs
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
        durationMs: 42.5
    )
}

public struct SSLChainResult: Equatable {
    public let hostname: String
    public let isValid: Bool
    public let issuer: String
    public let subject: String
    public let validFrom: Date?
    public let validTo: Date?
    public let daysRemaining: Int
    public let sans: [String]
    public let protocolVersion: String?
    public let errorDescription: String?
    
    public init(hostname: String, isValid: Bool, issuer: String, subject: String, validFrom: Date? = nil, validTo: Date? = nil, daysRemaining: Int = 90, sans: [String] = [], protocolVersion: String? = nil, errorDescription: String? = nil) {
        self.hostname = hostname
        self.isValid = isValid
        self.issuer = issuer
        self.subject = subject
        self.validFrom = validFrom
        self.validTo = validTo
        self.daysRemaining = daysRemaining
        self.sans = sans
        self.protocolVersion = protocolVersion
        self.errorDescription = errorDescription
    }
    
    public static let placeholder = SSLChainResult(
        hostname: "example.com",
        isValid: true,
        issuer: "GTS CA 1P5 (Google Trust Services)",
        subject: "CN=example.com",
        validFrom: Date(timeIntervalSince1970: 1700000000),
        validTo: Date(timeIntervalSince1970: 1800000000),
        daysRemaining: 84,
        sans: ["example.com", "*.example.com"],
        protocolVersion: "TLSv1.3"
    )
}

public struct IPLookupResult: Equatable {
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
    
    public init(query: String, ip: String, asn: String? = nil, org: String? = nil, country: String? = nil, countryCode: String? = nil, city: String? = nil, region: String? = nil, timezone: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
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
        longitude: -122.4194
    )
}

// MARK: - SSL Diagnostic Models

public struct SSLCertDetails: Identifiable, Equatable {
    public var id: String { commonName + (issuer ?? "") }
    public let commonName: String
    public let issuer: String?
    public let validityDaysRemaining: Int?
    public let protocolNegotiated: String?
    public let chainCount: Int
    public let isCloudflareEdge: Bool
    public let validFrom: String?
    public let validUntil: String?
    public let sans: [String]
    
    public init(commonName: String, issuer: String? = nil, validityDaysRemaining: Int? = 90, protocolNegotiated: String? = "TLSv1.3", chainCount: Int = 2, isCloudflareEdge: Bool = true, validFrom: String? = nil, validUntil: String? = nil, sans: [String] = []) {
        self.commonName = commonName
        self.issuer = issuer
        self.validityDaysRemaining = validityDaysRemaining
        self.protocolNegotiated = protocolNegotiated
        self.chainCount = chainCount
        self.isCloudflareEdge = isCloudflareEdge
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.sans = sans
    }
    
    public static let placeholder = SSLCertDetails(
        commonName: "cloudflare.com",
        issuer: "GTS CA 1P5 (Google Trust Services)",
        validityDaysRemaining: 84,
        protocolNegotiated: "TLSv1.3",
        chainCount: 2,
        isCloudflareEdge: true,
        validFrom: "2024-01-01 00:00:00 UTC",
        validUntil: "2024-12-31 23:59:59 UTC",
        sans: ["cloudflare.com", "*.cloudflare.com"]
    )
}
