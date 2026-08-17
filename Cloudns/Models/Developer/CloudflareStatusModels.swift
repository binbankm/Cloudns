import Foundation

// MARK: - Models for Cloudflare Statuspage

public struct CFStatusSummary: Codable {
    public let page: CFStatusPage?
    public let status: CFOverallStatus?
    public let components: [CFComponentItem]?
    public let incidents: [CFIncidentItem]?
    
    public init(page: CFStatusPage? = nil, status: CFOverallStatus? = nil, components: [CFComponentItem]? = nil, incidents: [CFIncidentItem]? = nil) {
        self.page = page
        self.status = status
        self.components = components
        self.incidents = incidents
    }
}

public struct CFStatusPage: Codable {
    public let id: String?
    public let name: String?
    public let url: String?
    public let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, url
        case updatedAt = "updated_at"
    }
    
    public init(id: String? = nil, name: String? = nil, url: String? = nil, updatedAt: String? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.updatedAt = updatedAt
    }
}

public struct CFOverallStatus: Codable {
    public let indicator: String // none, minor, major, critical
    public let description: String
    
    public init(indicator: String, description: String) {
        self.indicator = indicator
        self.description = description
    }
}

public struct CFComponentItem: Codable, Identifiable {
    public let id: String
    public let name: String
    public let status: String // operational, degraded_performance, partial_outage, major_outage
    public let description: String?
    public let position: Int?
    
    public init(id: String, name: String, status: String = "operational", description: String? = nil, position: Int? = 1) {
        self.id = id
        self.name = name
        self.status = status
        self.description = description
        self.position = position
    }
    
    public static let placeholders: [CFComponentItem] = [
        CFComponentItem(id: "1", name: "Authoritative DNS"),
        CFComponentItem(id: "2", name: "Cloudflare Dashboard"),
        CFComponentItem(id: "3", name: "Cloudflare Workers"),
        CFComponentItem(id: "4", name: "Cloudflare Pages"),
        CFComponentItem(id: "5", name: "R2 Object Storage"),
        CFComponentItem(id: "6", name: "D1 SQL Database")
    ]
}

public struct CFIncidentItem: Codable, Identifiable {
    public let id: String
    public let name: String
    public let status: String // resolved, monitoring, identified, investigating
    public let impact: String // none, minor, major, critical
    public let createdAt: String?
    public let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, status, impact
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(id: String, name: String, status: String, impact: String, createdAt: String? = nil, updatedAt: String? = nil) {
        self.id = id
        self.name = name
        self.status = status
        self.impact = impact
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
