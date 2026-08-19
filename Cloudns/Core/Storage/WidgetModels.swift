import Foundation

// MARK: - Widget Snapshot Models

public struct ZoneWidgetSnapshot: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let status: String
    public let plan: String
    public let requests24h: Int
    public let cachedRatio: Double
    public let threats24h: Int
    public let isProxied: Bool
    public let isSSLEnabled: Bool
    public let lastUpdated: Date
    
    public init(
        id: String,
        name: String,
        status: String = "active",
        plan: String = "Free",
        requests24h: Int = 0,
        cachedRatio: Double = 0.0,
        threats24h: Int = 0,
        isProxied: Bool = true,
        isSSLEnabled: Bool = true,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.plan = plan
        self.requests24h = requests24h
        self.cachedRatio = cachedRatio
        self.threats24h = threats24h
        self.isProxied = isProxied
        self.isSSLEnabled = isSSLEnabled
        self.lastUpdated = lastUpdated
    }
    
    public var formattedRequests: String {
        if requests24h >= 1_000_000 {
            return String(format: "%.1fM", Double(requests24h) / 1_000_000.0)
        } else if requests24h >= 1_000 {
            return String(format: "%.1fK", Double(requests24h) / 1_000.0)
        } else {
            return "\(requests24h)"
        }
    }
    
    public var formattedCachedRatio: String {
        return "\(Int(cachedRatio * 100))%"
    }
    
    public static let placeholder = ZoneWidgetSnapshot(
        id: "placeholder-zone-id",
        name: "example.com",
        status: "active",
        plan: "Pro Plan",
        requests24h: 124500,
        cachedRatio: 0.78,
        threats24h: 142,
        isProxied: true,
        isSSLEnabled: true,
        lastUpdated: Date()
    )
}

public struct CFStatusWidgetSnapshot: Codable, Sendable {
    public let indicator: String // none, minor, major, critical, maintenance
    public let description: String
    public let activeIncidentsCount: Int
    public let latestIncidentTitle: String?
    public let lastUpdated: Date
    
    public init(
        indicator: String = "none",
        description: String = "All Systems Operational",
        activeIncidentsCount: Int = 0,
        latestIncidentTitle: String? = nil,
        lastUpdated: Date = Date()
    ) {
        self.indicator = indicator
        self.description = description
        self.activeIncidentsCount = activeIncidentsCount
        self.latestIncidentTitle = latestIncidentTitle
        self.lastUpdated = lastUpdated
    }
    
    public var isOperational: Bool {
        indicator.lowercased() == "none" || indicator.isEmpty
    }
    
    public static let placeholder = CFStatusWidgetSnapshot(
        indicator: "none",
        description: "All Systems Operational",
        activeIncidentsCount: 0,
        latestIncidentTitle: nil,
        lastUpdated: Date()
    )
}
