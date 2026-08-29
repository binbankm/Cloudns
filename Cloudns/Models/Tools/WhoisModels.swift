import Foundation

// MARK: - WHOIS Info Model

public struct WhoisInfo: Identifiable, Sendable {
    public nonisolated var id: String { domain }
    public let domain: String
    public let statuses: [String]
    public let registrar: String?
    public let created: Date?
    public let updated: Date?
    public let expires: Date?
    public let nameservers: [String]
    
    public nonisolated init(
        domain: String,
        statuses: [String] = [],
        registrar: String? = nil,
        created: Date? = nil,
        updated: Date? = nil,
        expires: Date? = nil,
        nameservers: [String] = []
    ) {
        self.domain = domain
        self.statuses = statuses
        self.registrar = registrar
        self.created = created
        self.updated = updated
        self.expires = expires
        self.nameservers = nameservers
    }
    
    public static let placeholder = WhoisInfo(
        domain: "example.com",
        statuses: ["clientTransferProhibited", "active"],
        registrar: "Cloudflare, Inc.",
        created: Date(timeIntervalSince1970: 800000000),
        updated: Date(timeIntervalSince1970: 1700000000),
        expires: Date(timeIntervalSince1970: 1800000000),
        nameservers: ["ns1.cloudflare.com", "ns2.cloudflare.com"]
    )
}
