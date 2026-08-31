import Foundation
import SwiftUI

// MARK: - DNS Dig & Benchmark Diagnostic Models

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
