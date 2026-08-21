import Foundation

// MARK: - Widget Snapshot Models

public struct ZoneWidgetSnapshot: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let status: String
    public let plan: String
    public let requests24h: Int
    public let bytes24h: Int
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
        bytes24h: Int = 0,
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
        self.bytes24h = bytes24h
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
    
    public var formattedBytes: String {
        let b = Double(bytes24h)
        if b >= 1_073_741_824 {
            return String(format: "%.1f GB", b / 1_073_741_824.0)
        } else if b >= 1_048_576 {
            return String(format: "%.1f MB", b / 1_048_576.0)
        } else if b >= 1_024 {
            return String(format: "%.1f KB", b / 1_024.0)
        } else {
            return "\(bytes24h) B"
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
        bytes24h: 2450000000,
        cachedRatio: 0.78,
        threats24h: 142,
        isProxied: true,
        isSSLEnabled: true
    )
}

// MARK: - Worker Widget Snapshot

public struct WorkerWidgetSnapshot: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let requests24h: Int
    public let errors24h: Int
    public let cpuTimeMs: Double
    public let successRate: Double
    public let lastUpdated: Date
    
    public init(
        id: String,
        name: String,
        requests24h: Int = 0,
        errors24h: Int = 0,
        cpuTimeMs: Double = 0.0,
        successRate: Double = 1.0,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.requests24h = requests24h
        self.errors24h = errors24h
        self.cpuTimeMs = cpuTimeMs
        self.successRate = successRate
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
    
    public var formattedSuccessRate: String {
        return String(format: "%.1f%%", successRate * 100)
    }
    
    public var formattedCpuTime: String {
        if cpuTimeMs >= 1000 {
            return String(format: "%.1fs", cpuTimeMs / 1000.0)
        } else {
            return String(format: "%.1fms", cpuTimeMs)
        }
    }
    
    public static let placeholder = WorkerWidgetSnapshot(
        id: "placeholder-worker",
        name: "api-service",
        requests24h: 84200,
        errors24h: 12,
        cpuTimeMs: 2.4,
        successRate: 0.999
    )
}

// MARK: - Pages Widget Snapshot

public struct PagesWidgetSnapshot: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let subdomain: String
    public let productionBranch: String
    public let latestStatus: String
    public let requests24h: Int
    public let errors24h: Int
    public let lastUpdated: Date
    
    public init(
        id: String,
        name: String,
        subdomain: String = "pages.dev",
        productionBranch: String = "main",
        latestStatus: String = "success",
        requests24h: Int = 0,
        errors24h: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.subdomain = subdomain
        self.productionBranch = productionBranch
        self.latestStatus = latestStatus
        self.requests24h = requests24h
        self.errors24h = errors24h
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
    
    public static let placeholder = PagesWidgetSnapshot(
        id: "placeholder-pages",
        name: "cloudns-docs",
        subdomain: "cloudns-docs.pages.dev",
        productionBranch: "main",
        latestStatus: "success",
        requests24h: 42100,
        errors24h: 3
    )
}

// MARK: - CF Status Widget Snapshot

public struct CFStatusWidgetSnapshot: Codable, Sendable {
    public let indicator: String
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
        return (indicator == "none" || indicator.isEmpty) && activeIncidentsCount == 0
    }
    
    public static let placeholder = CFStatusWidgetSnapshot(
        indicator: "none",
        description: "All Systems Operational",
        activeIncidentsCount: 0,
        latestIncidentTitle: nil
    )
    
    public static let operational = placeholder
}
